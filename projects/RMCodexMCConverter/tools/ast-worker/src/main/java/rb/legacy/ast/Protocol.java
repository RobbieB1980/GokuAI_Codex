package rb.legacy.ast;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;

import java.util.List;

public final class Protocol {
    public static final int VERSION = 1;
    private static final Gson GSON = new GsonBuilder().disableHtmlEscaping().create();

    private Protocol() {
    }

    public static Request parseRequest(String json) throws InvalidRequestException {
        try {
            JsonObject object = JsonParser.parseString(json).getAsJsonObject();
            int protocolVersion = requiredInt(object, "protocolVersion");
            String operation = requiredString(object, "operation");
            String sourceRoot = requiredString(object, "sourceRoot");
            if (protocolVersion != VERSION) {
                throw new InvalidRequestException("Unsupported protocolVersion: " + protocolVersion);
            }
            if (!"analyze".equals(operation)) {
                throw new InvalidRequestException("Unsupported operation: " + operation);
            }
            if (sourceRoot.isBlank()) {
                throw new InvalidRequestException("sourceRoot must not be blank");
            }
            List<String> classpath = object.has("classpath")
                    ? GSON.fromJson(object.get("classpath"), StringList.TYPE)
                    : List.of();
            if (classpath == null || classpath.stream().anyMatch(value -> value == null || value.isBlank())) {
                throw new InvalidRequestException("classpath must contain only non-blank strings");
            }
            return new Request(protocolVersion, operation, sourceRoot, List.copyOf(classpath));
        } catch (InvalidRequestException exception) {
            throw exception;
        } catch (JsonParseException | IllegalStateException | NullPointerException exception) {
            throw new InvalidRequestException("Invalid JSON request", exception);
        }
    }

    private static int requiredInt(JsonObject object, String name) throws InvalidRequestException {
        if (!object.has(name) || !object.get(name).isJsonPrimitive()) {
            throw new InvalidRequestException("Missing integer field: " + name);
        }
        try {
            return object.get(name).getAsInt();
        } catch (NumberFormatException exception) {
            throw new InvalidRequestException("Invalid integer field: " + name, exception);
        }
    }

    private static String requiredString(JsonObject object, String name) throws InvalidRequestException {
        if (!object.has(name) || !object.get(name).isJsonPrimitive()) {
            throw new InvalidRequestException("Missing string field: " + name);
        }
        return object.get(name).getAsString();
    }

    public static String toJson(Response response) {
        return GSON.toJson(response);
    }

    public record Request(int protocolVersion, String operation, String sourceRoot, List<String> classpath) {
    }

    public record ParseFailure(String path, List<String> problems) {
        public ParseFailure {
            problems = List.copyOf(problems);
        }
    }

    public record Response(
            int protocolVersion,
            String status,
            List<String> parsedFiles,
            List<ParseFailure> parseFailures,
            List<String> declaredTypes,
            List<String> imports,
            List<String> diagnostics
    ) {
        public Response {
            parsedFiles = List.copyOf(parsedFiles);
            parseFailures = List.copyOf(parseFailures);
            declaredTypes = List.copyOf(declaredTypes);
            imports = List.copyOf(imports);
            diagnostics = List.copyOf(diagnostics);
        }

        public static Response success(
                List<String> parsedFiles,
                List<ParseFailure> parseFailures,
                List<String> declaredTypes,
                List<String> imports,
                List<String> diagnostics
        ) {
            return new Response(VERSION, "ok", parsedFiles, parseFailures, declaredTypes, imports, diagnostics);
        }

        public static Response error(String status, String diagnostic) {
            return new Response(VERSION, status, List.of(), List.of(), List.of(), List.of(), List.of(diagnostic));
        }
    }

    public static final class InvalidRequestException extends Exception {
        public InvalidRequestException(String message) {
            super(message);
        }

        public InvalidRequestException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    private static final class StringList {
        private static final java.lang.reflect.Type TYPE =
                com.google.gson.reflect.TypeToken.getParameterized(List.class, String.class).getType();
    }
}
