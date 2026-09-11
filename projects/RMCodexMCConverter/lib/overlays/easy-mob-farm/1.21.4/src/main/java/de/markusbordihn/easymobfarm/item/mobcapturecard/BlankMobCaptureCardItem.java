package de.markusbordihn.easymobfarm.item.mobcapturecard;

import net.minecraft.core.registries.Registries;
import net.minecraft.resources.Identifier;
import net.minecraft.resources.ResourceKey;
import net.minecraft.world.item.Item;

public class BlankMobCaptureCardItem extends Item {
   public static final String ID = "blank_mob_capture_card";

   public BlankMobCaptureCardItem() {
      this(new Item.Properties().setId(ResourceKey.create(Registries.ITEM, Identifier.fromNamespaceAndPath("easy_mob_farm", "blank_mob_capture_card"))));
   }

   public BlankMobCaptureCardItem(Item.Properties properties) {
      super(properties);
   }
}
