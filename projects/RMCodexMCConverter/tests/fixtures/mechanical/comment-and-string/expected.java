package example;

import net.minecraft.resources.Identifier;

// Identifier in a comment demonstrates the legacy text-rewrite boundary.
class Identifier {
    String literal = "Identifier";
    Identifier value = Identifier.fromNamespaceAndPath("example", "thing");
}
