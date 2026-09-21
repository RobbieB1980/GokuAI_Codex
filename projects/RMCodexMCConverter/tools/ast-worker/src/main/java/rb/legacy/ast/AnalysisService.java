package rb.legacy.ast;

import com.github.javaparser.JavaParser;
import com.github.javaparser.ParseResult;
import com.github.javaparser.ParserConfiguration;
import com.github.javaparser.Problem;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.symbolsolver.JavaSymbolSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.CombinedTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.JavaParserTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.JarTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.ReflectionTypeSolver;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.TreeSet;
import java.util.stream.Stream;

public final class AnalysisService {
    public Protocol.Response analyze(Protocol.Request request) throws IOException {
        Path sourceRoot = Path.of(request.sourceRoot()).toAbsolutePath().normalize();
        if (!Files.isDirectory(sourceRoot)) {
            throw new IOException("sourceRoot is not a directory: " + sourceRoot);
        }

        CombinedTypeSolver typeSolver = new CombinedTypeSolver();
        typeSolver.add(new ReflectionTypeSolver());
        typeSolver.add(new JavaParserTypeSolver(sourceRoot));
        for (String entry : request.classpath()) {
            Path jar = Path.of(entry).toAbsolutePath().normalize();
            if (!Files.isRegularFile(jar)) {
                throw new IOException("Classpath JAR does not exist: " + jar);
            }
            typeSolver.add(new JarTypeSolver(jar));
        }

        ParserConfiguration configuration = new ParserConfiguration()
                .setLanguageLevel(ParserConfiguration.LanguageLevel.BLEEDING_EDGE)
                .setSymbolResolver(new JavaSymbolSolver(typeSolver));
        JavaParser parser = new JavaParser(configuration);

        List<String> parsedFiles = new ArrayList<>();
        List<Protocol.ParseFailure> parseFailures = new ArrayList<>();
        TreeSet<String> declaredTypes = new TreeSet<>();
        TreeSet<String> imports = new TreeSet<>();

        List<Path> sourceFiles;
        try (Stream<Path> paths = Files.walk(sourceRoot)) {
            sourceFiles = paths
                    .filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().endsWith(".java"))
                    .sorted(Comparator.comparing(path -> relativePath(sourceRoot, path)))
                    .toList();
        }

        for (Path sourceFile : sourceFiles) {
            String relative = relativePath(sourceRoot, sourceFile);
            ParseResult<CompilationUnit> result = parser.parse(sourceFile);
            if (!result.isSuccessful() || result.getResult().isEmpty()) {
                List<String> problems = result.getProblems().stream()
                        .map(Problem::getVerboseMessage)
                        .toList();
                parseFailures.add(new Protocol.ParseFailure(relative, problems));
                continue;
            }

            CompilationUnit unit = result.getResult().orElseThrow();
            parsedFiles.add(relative);
            String packagePrefix = unit.getPackageDeclaration()
                    .map(declaration -> declaration.getNameAsString() + ".")
                    .orElse("");
            unit.getTypes().forEach(type -> declaredTypes.add(packagePrefix + type.getNameAsString()));
            unit.getImports().forEach(importDeclaration -> imports.add(importDeclaration.getNameAsString()));
        }

        return Protocol.Response.success(
                parsedFiles,
                parseFailures,
                new ArrayList<>(declaredTypes),
                new ArrayList<>(imports),
                List.of()
        );
    }

    private static String relativePath(Path root, Path path) {
        return root.relativize(path).toString().replace('\\', '/');
    }
}
