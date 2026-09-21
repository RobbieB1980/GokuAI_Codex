package example;

import net.minecraft.client.model.CowModel;
import net.minecraft.client.model.PigModel;
import net.minecraft.world.item.PickaxeItem;

class ExamplePickaxe extends PickaxeItem {
    ExamplePickaxe(Properties properties) {
        super(TOOL_MATERIAL, 1.0F, -2.8F, properties);
    }

    void migrate(Level world, LightningBolt entityToSpawn, GuiGraphics guiGraphics) {
        long time = world.getDayTime();
        entityToSpawn.moveTo(Vec3.atBottomCenterOf(pos));
        new KeyMapping("key.example", 65, "key.categories.misc");
        REGISTRY.registerBlock(name, supplier, Properties.of());
        new ArrayList(world.players());
        guiGraphics.extractTooltip(font, stack, mouseX, mouseY);
        super.render(guiGraphics, mouseX, mouseY, partialTicks);
        RenderTypes.eyes(texture);
        storage.computeIfAbsent(new SavedData.Factory(ExampleData::new, ExampleData::load), "example");
    }
}
