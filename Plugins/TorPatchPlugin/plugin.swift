import PackagePlugin
import Foundation

@main
struct TorPatchPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        print("🔧 TorPatchPlugin: Starting patch application...")
        
        // Найти crypto_rand_fast.c динамически
        let packageDir = context.package.directory
        
        // Возможные пути для поиска
        let possiblePaths = [
            "Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c",
            "tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c",
            "Sources/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c",
        ]
        
        // Путь к пропатченному файлу
        let patchedFilePath = packageDir
            .appending(subpath: "patches/tor-0.4.8.19/src/lib/crypt_ops/crypto_rand_fast.c.patched")
        
        // Выходной файл для отслеживания
        let outputFile = context.pluginWorkDirectory
            .appending(subpath: "patch_applied.marker")
        
        // Python скрипт для применения патча
        let patchScript = """
        import sys
        import os
        import shutil
        
        package_dir = '\(packageDir.string)'
        patched_file = '\(patchedFilePath.string)'
        marker_path = '\(outputFile.string)'
        
        print('🔧 TorPatchPlugin: Searching for crypto_rand_fast.c...')
        
        # Найти все crypto_rand_fast.c файлы
        possible_paths = [
            'Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c',
            'tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c',
            'Sources/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c',
        ]
        
        target_files = []
        for rel_path in possible_paths:
            full_path = os.path.join(package_dir, rel_path)
            if os.path.exists(full_path):
                target_files.append(full_path)
                print(f'   ✅ Found: {rel_path}')
        
        if not target_files:
            print('⚠️  WARNING: crypto_rand_fast.c not found')
            print('   This may be normal if sources haven\\'t been extracted yet')
            # Create marker anyway
            os.makedirs(os.path.dirname(marker_path), exist_ok=True)
            with open(marker_path, 'w') as f:
                f.write('skipped_no_sources')
            sys.exit(0)
        
        # Проверить наличие пропатченного файла
        if not os.path.exists(patched_file):
            print(f'❌ ERROR: Patched file not found: {patched_file}')
            sys.exit(1)
        
        print(f'✅ Patched file found: {patched_file}')
        
        # Применить патч к каждому файлу
        patched_count = 0
        already_patched_count = 0
        
        for target_file in target_files:
            print(f'\\n📄 Processing: {target_file}')
            
            # Проверить: уже пропатчено?
            with open(target_file, 'r') as f:
                content = f.read()
            
            if 'iOS PATCH' in content or 'Using memory with INHERIT_RES_KEEP' in content:
                print('   ✅ Already patched - skipping')
                already_patched_count += 1
                continue
            
            print('   🔧 Applying patch...')
            
            # Backup
            backup_file = target_file + '.bak'
            shutil.copy2(target_file, backup_file)
            
            # Copy patched version
            shutil.copy2(patched_file, target_file)
            
            # Verify
            with open(target_file, 'r') as f:
                new_content = f.read()
            
            if 'iOS PATCH' in new_content or 'Using memory with INHERIT_RES_KEEP' in new_content:
                print('   ✅✅✅ Patch applied successfully!')
                os.remove(backup_file)
                patched_count += 1
            else:
                print('   ❌ VERIFICATION FAILED! Restoring backup...')
                shutil.copy2(backup_file, target_file)
                os.remove(backup_file)
                sys.exit(1)
        
        # Summary
        print('\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('✅ PATCH APPLICATION COMPLETE!')
        print(f'   Files patched now:     {patched_count}')
        print(f'   Files already patched: {already_patched_count}')
        
        # Create marker
        os.makedirs(os.path.dirname(marker_path), exist_ok=True)
        with open(marker_path, 'w') as f:
            f.write(f'patched={patched_count},already={already_patched_count}')
        
        print('✅ Ready for compilation!')
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

