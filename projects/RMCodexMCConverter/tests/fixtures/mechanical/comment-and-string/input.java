package example;

import net.minecraft.resources.ResourceLocation;

// ResourceLocation in a comment demonstrates the legacy text-rewrite boundary.
class ResourceLocation {
    String literal = "ResourceLocation";
    ResourceLocation value = new ResourceLocation("example", "thing");
}
