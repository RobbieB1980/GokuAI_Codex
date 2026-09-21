<#
.SYNOPSIS
  Apply Mel DeCo NeoForge 26.2 API wave fixes to an already-scaffolded project.
  Mirrors rules encoded in Convert-Forge1201-ToNeoForge262.ps1 (API + Mcreator1218).
#>
param(
    [Parameter(Mandatory)][string]$Root
)

$ErrorActionPreference = 'Stop'
$files = Get-ChildItem (Join-Path $Root 'src\main\java') -Recurse -Filter '*.java' -File -ErrorAction SilentlyContinue
$touched = 0

foreach ($f in $files) {
    $t = [System.IO.File]::ReadAllText($f.FullName)
    $o = $t

    # PersistentData Optional accessors
    $t = $t -replace '\.getPersistentData\(\)\.getBoolean\(([^)]+)\)', '.getPersistentData().getBooleanOr($1, false)'
    $t = $t -replace '\.getPersistentData\(\)\.getString\(([^)]+)\)', '.getPersistentData().getStringOr($1, "")'
    $t = $t -replace '\.getPersistentData\(\)\.getInt\(([^)]+)\)', '.getPersistentData().getIntOr($1, 0)'
    $t = $t -replace '\.getPersistentData\(\)\.getDouble\(([^)]+)\)', '.getPersistentData().getDoubleOr($1, 0.0)'

    # loadWithComponents(CompoundTag, RegistryAccess) -> TagValueInput
    if ($t -match '\.loadWithComponents\s*\(\s*\w+\s*,') {
        $t = [regex]::Replace($t,
            '\.loadWithComponents\s*\(\s*(\w+)\s*,\s*([^)]+?)\.registryAccess\(\)\s*\)',
            '.loadWithComponents(TagValueInput.create(ProblemReporter.DISCARDING, $2.registryAccess(), $1))')
        if ($t -match '\bTagValueInput\b' -and $t -notmatch 'import\s+net\.minecraft\.world\.level\.storage\.TagValueInput\s*;') {
            $t = [regex]::Replace($t, '(?m)^(package\s+[^;]+;\s*)',
                "`$1`r`nimport net.minecraft.util.ProblemReporter;`r`nimport net.minecraft.world.level.storage.TagValueInput;`r`n", 1)
        }
    }

    # CommandSourceStack permission int -> LevelBasedPermissionSet (_levelx* locals)
    $t = $t -replace '(_level\w*|_serverLevel\w*|serverLevel|level)\s*,\s*4\s*,',
        '$1, net.minecraft.server.permissions.LevelBasedPermissionSet.OWNER,'
    $t = $t -replace '(_level\w*|_serverLevel\w*|serverLevel|level)\s*,\s*2\s*,',
        '$1, net.minecraft.server.permissions.LevelBasedPermissionSet.GAMEMASTER,'
    $t = $t -replace '(_level\w*|_serverLevel\w*|serverLevel|level)\s*,\s*3\s*,',
        '$1, net.minecraft.server.permissions.LevelBasedPermissionSet.ADMIN,'

    # PacketDistributor: keep server sendToPlayer import; client sendToServer -> ClientPacketDistributor
    # Negative lookbehind avoids ClientPacketDistributor -> ClientClientPacketDistributor
    $t = $t -replace 'ClientClientPacketDistributor', 'ClientPacketDistributor'
    if ($t -match '(?<!Client)PacketDistributor\.sendToServer') {
        $t = [regex]::Replace($t, '(?<!Client)PacketDistributor\.sendToServer', 'ClientPacketDistributor.sendToServer')
        if ($t -match '(?<!Client)PacketDistributor\.sendToPlayer' -or $t -match '(?<!\w)PacketDistributor\.sendToPlayer') {
            if ($t -notmatch 'import\s+net\.neoforged\.neoforge\.client\.network\.ClientPacketDistributor;') {
                $t = [regex]::Replace($t, '(?m)^(package\s+[^;]+;\s*)', "`$1`r`nimport net.neoforged.neoforge.client.network.ClientPacketDistributor;`r`n", 1)
            }
            if ($t -notmatch 'import\s+net\.neoforged\.neoforge\.network\.PacketDistributor;') {
                $t = [regex]::Replace($t, '(?m)^(package\s+[^;]+;\s*)', "`$1`r`nimport net.neoforged.neoforge.network.PacketDistributor;`r`n", 1)
            }
        }
        else {
            $t = $t -replace 'import\s+net\.neoforged\.neoforge\.network\.PacketDistributor;', 'import net.neoforged.neoforge.client.network.ClientPacketDistributor;'
            if ($t -notmatch 'import\s+net\.neoforged\.neoforge\.client\.network\.ClientPacketDistributor;') {
                $t = [regex]::Replace($t, '(?m)^(package\s+[^;]+;\s*)', "`$1`r`nimport net.neoforged.neoforge.client.network.ClientPacketDistributor;`r`n", 1)
            }
        }
    }
    elseif ($t -match '(?<!\w)PacketDistributor\.sendToPlayer' -and $t -notmatch 'import\s+net\.neoforged\.neoforge\.network\.PacketDistributor;') {
        $t = [regex]::Replace($t, '(?m)^(package\s+[^;]+;\s*)', "`$1`r`nimport net.neoforged.neoforge.network.PacketDistributor;`r`n", 1)
    }

    # hurtEnemy void leftover boolean return
    $t = [regex]::Replace($t,
        'public\s+boolean\s+hurtEnemy\s*\(\s*ItemStack\s+(\w+)\s*,\s*LivingEntity\s+(\w+)\s*,\s*LivingEntity\s+(\w+)\s*\)',
        'public void hurtEnemy(ItemStack $1, LivingEntity $2, LivingEntity $3)')
    $t = [regex]::Replace($t,
        '(public\s+void\s+hurtEnemy\s*\([^)]*\)\s*\{(?:[^{}]|\{[^{}]*\})*?)return\s+(?:true|false)\s*;',
        '$1')

    # inventoryTick: fix literal $4 leftover; armor worn check
    $t = $t -replace 'super\.inventoryTick\(([^,]+),\s*([^,]+),\s*([^,]+),\s*\$4\)', 'super.inventoryTick($1, $2, $3, slot)'
    $t = [regex]::Replace($t,
        'super\.inventoryTick\s*\(\s*(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*\w+\s*\)',
        'super.inventoryTick($1, $2, $3, $4)')
    $armorWorn = 'java.util.List.of($1.getItemBySlot(net.minecraft.world.entity.EquipmentSlot.HEAD), $1.getItemBySlot(net.minecraft.world.entity.EquipmentSlot.CHEST), $1.getItemBySlot(net.minecraft.world.entity.EquipmentSlot.LEGS), $1.getItemBySlot(net.minecraft.world.entity.EquipmentSlot.FEET)).contains($2)'
    $t = [regex]::Replace($t,
        'Iterables\.contains\(\s*(\w+)\.getArmorSlots\(\)\s*,\s*(\w+)\s*\)',
        $armorWorn)
    $t = [regex]::Replace($t,
        'Iterables\.contains\(\s*(\w+)\.getEquippedSlots\s*\(\s*net\.minecraft\.world\.entity\.EquipmentSlotGroup\.ARMOR\s*\)\s*,\s*(\w+)\s*\)',
        $armorWorn)

    # ItemOwner for item model / range select properties
    if ($t -match 'RangeSelectItemModelProperty|implements\s+ItemModel\b|LegacyOverrideSelectItemModel') {
        $t = [regex]::Replace($t,
            '(public\s+float\s+get\s*\(\s*ItemStack\s+\w+\s*,\s*@Nullable\s+ClientLevel\s+\w+\s*,\s*@Nullable\s+)LivingEntity(\s+)(\w+)(\s*,\s*int\s+\w+\s*\))',
            '${1}ItemOwner${2}${3}${4}')
        $t = $t -replace '@Nullable LivingEntity entity', '@Nullable ItemOwner entity'
        $t = $t -replace '@Nullable LivingEntity var3', '@Nullable ItemOwner var3'
        if ($t -notmatch 'DisplaySprayPaintDesignItemProcedure\.execute\([^)]*asLivingEntity') {
            $t = [regex]::Replace($t,
                'DisplaySprayPaintDesignItemProcedure\.execute\((\w+)\)',
                'DisplaySprayPaintDesignItemProcedure.execute($1 != null ? $1.asLivingEntity() : null)')
        }
        # ConditionalItemModelProperty.get still wants LivingEntity
        $t = $t.Replace(
            'this.property.get(itemStack, level, entity, seed, displayContext)',
            'this.property.get(itemStack, level, entity == null ? null : entity.asLivingEntity(), seed, displayContext)')
        if ($t -match '\bItemOwner\b' -and $t -notmatch 'import\s+net\.minecraft\.world\.entity\.ItemOwner\s*;') {
            $t = [regex]::Replace($t, '(?m)^(package\s+[^;]+;\s*)',
                "`$1`r`nimport net.minecraft.world.entity.ItemOwner;`r`n", 1)
        }
    }

    if ($t -ne $o) {
        [System.IO.File]::WriteAllText($f.FullName, $t)
        $touched++
    }
}

Write-Host "Mel API wave touched $touched file(s)"
return $touched
