package example;
import net.minecraft.client.renderer.rendertype.RenderTypes;

import net.minecraft.client.model.animal.cow.CowModel;
import net.minecraft.client.model.animal.pig.PigModel;
import net.minecraft.world.item.Item;

class ExamplePickaxe extends Item {
    ExamplePickaxe(Properties properties) {
        super(properties.pickaxe(TOOL_MATERIAL, 1.0F, -2.8F));
    }

    void migrate(Level world, LightningBolt entityToSpawn, GuiGraphics guiGraphics) {
        long time = world.getOverworldClockTime();
        entityToSpawn.snapTo(Vec3.atBottomCenterOf(pos));
        new KeyMapping("key.example", 65, KeyMapping.Category.MISC);
        REGISTRY.registerBlock(name, supplier, () -> Properties.of());
        new ArrayList<>(world.players());
        guiGraphics.setTooltipForNextFrame(font, stack, mouseX, mouseY);
        super.extractRenderState(guiGraphics, mouseX, mouseY, partialTicks);
        RenderTypes.eyes(texture);
        storage.computeIfAbsent(TYPE);
    }
}
