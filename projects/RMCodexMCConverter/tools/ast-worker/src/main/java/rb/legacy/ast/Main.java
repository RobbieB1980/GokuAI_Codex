package rb.legacy.ast;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

public final class Main {
    private Main() {
    }

    public static void main(String[] args) {
        int exitCode = run();
        if (exitCode != 0) {
            System.exit(exitCode);
        }
    }

    static int run() {
        try {
            String input = new String(System.in.readAllBytes(), StandardCharsets.UTF_8);
            Protocol.Request request = Protocol.parseRequest(input);
            writeResponse(new AnalysisService().analyze(request));
            return 0;
        } catch (Protocol.InvalidRequestException exception) {
            writeResponse(Protocol.Response.error("invalid_request", exception.getMessage()));
            return 2;
        } catch (Exception exception) {
            String message = exception.getMessage() == null ? exception.getClass().getName() : exception.getMessage();
            writeResponse(Protocol.Response.error("worker_error", message));
            return 3;
        }
    }

    private static void writeResponse(Protocol.Response response) {
        try {
            Writer writer = new OutputStreamWriter(System.out, StandardCharsets.UTF_8);
            writer.write(Protocol.toJson(response));
            writer.write(System.lineSeparator());
            writer.flush();
        } catch (IOException exception) {
            throw new IllegalStateException("Could not write worker response", exception);
        }
    }
}
