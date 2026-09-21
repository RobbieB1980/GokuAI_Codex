package rb.legacy.ast;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AnalysisServiceTest {
    @TempDir
    Path sourceRoot;

    @Test
    void continuesAnalysisAfterAnIndividualParseFailure() throws Exception {
        Path packageRoot = Files.createDirectories(sourceRoot.resolve("demo"));
        Files.writeString(packageRoot.resolve("Valid.java"), """
                package demo;
                import java.util.List;
                public class Valid { List<String> values; }
                """);
        Files.writeString(packageRoot.resolve("Broken.java"), """
                package demo;
                public class Broken {
                """);

        Protocol.Request request = new Protocol.Request(
                1, "analyze", sourceRoot.toAbsolutePath().toString(), List.of()
        );
        Protocol.Response response = new AnalysisService().analyze(request);

        assertEquals("ok", response.status());
        assertEquals(List.of("demo/Valid.java"), response.parsedFiles());
        assertEquals(1, response.parseFailures().size());
        assertEquals("demo/Broken.java", response.parseFailures().getFirst().path());
        assertEquals(List.of("demo.Valid"), response.declaredTypes());
        assertEquals(List.of("java.util.List"), response.imports());
    }
}
