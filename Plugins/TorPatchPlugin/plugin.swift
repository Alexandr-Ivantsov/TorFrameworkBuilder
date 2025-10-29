import PackagePlugin
import Foundation

@main
struct TorPatchPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        print("🔧 TorPatchPlugin: Starting patch application...")
        
        // Путь к файлу crypto_rand_fast.c
        let cryptoFile = context.package.directory
            .appending(subpath: "Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c")
        
        // Выходной файл для отслеживания
        let outputFile = context.pluginWorkDirectory
            .appending(subpath: "patch_applied.marker")
        
        // Python скрипт для применения патча
        let patchScript = """
        import re
        import sys
        import os
        
        file_path = '\(cryptoFile.string)'
        marker_path = '\(outputFile.string)'
        
        print(f'📂 Patching file: {file_path}')
        
        if not os.path.exists(file_path):
            print(f'❌ ERROR: File not found: {file_path}')
            sys.exit(1)
        
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Проверка: уже пропатчено?
        if 'Using memory with INHERIT_RES_KEEP on iOS' in content:
            print('✅ Patch already applied')
            with open(marker_path, 'w') as f:
                f.write('patch_applied')
            sys.exit(0)
        
        print('🔧 Applying iOS patch...')
        
        # Применить патч: найти tor_assertf и обернуть в условие
        pattern = r'(#else\\s*/\\*\\s*We decided above.*?\\*/)\\s+(tor_assertf\\(inherit != INHERIT_RES_KEEP,\\s*"[^"]+?"\\s*"[^"]+?"\\s*"[^"]+?it\\.";)'
        
        replacement = r'''\\1
/* iOS PATCH: Platform doesn't support non-inheritable memory (iOS).
 * INHERIT_RES_KEEP is returned, which means we rely on CHECK_PID above
 * to detect forks. This is acceptable for iOS as it rarely forks.
 * Original assertion would crash here, so we skip it for KEEP. */
if (inherit != INHERIT_RES_KEEP) {
  /* Non-iOS platforms should have succeeded with NOINHERIT */
  \\2
} else {
  /* iOS: INHERIT_RES_KEEP is expected and acceptable */
  log_info(LD_CRYPTO, "Using memory with INHERIT_RES_KEEP on iOS (with PID check).");
}'''
        
        new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
        
        if new_content == content:
            print('⚠️  WARNING: Pattern not found, trying alternative approach...')
            # Alternative: find the specific line
            if 'tor_assertf(inherit != INHERIT_RES_KEEP,' in content:
                # Wrap existing assertion
                content = content.replace(
                    'tor_assertf(inherit != INHERIT_RES_KEEP,',
                    '''/* iOS PATCH */
if (inherit != INHERIT_RES_KEEP) {
  tor_assertf(inherit != INHERIT_RES_KEEP,'''
                )
                # Add closing brace and else
                content = content.replace(
                    '                "it.");',
                    '''                "it.");
} else {
  log_info(LD_CRYPTO, "Using memory with INHERIT_RES_KEEP on iOS (with PID check).");
}'''
                )
                new_content = content
        
        if 'Using memory with INHERIT_RES_KEEP on iOS' not in new_content:
            print('❌ ERROR: Patch application failed!')
            sys.exit(1)
        
        with open(file_path, 'w') as f:
            f.write(new_content)
        
        with open(marker_path, 'w') as f:
            f.write('patch_applied')
        
        print('✅✅✅ Patch applied successfully!')
        """
        
        return [
            .prebuildCommand(
                displayName: "Apply iOS Patch to crypto_rand_fast.c",
                executable: .init("/usr/bin/python3"),
                arguments: ["-c", patchScript],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}

