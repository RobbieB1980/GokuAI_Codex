package rb.legacy.ast;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ProtocolTest {
    @Test
    void acceptsTheSupportedAnalyzeRequest() throws Exception {
        Protocol.Request request = Protocol.parseRequest("""
                {"protocolVersion":1,"operation":"analyze","sourceRoot":"C:/source","classpath":[]}
                """);

        assertEquals(1, request.protocolVersion());
        assertEquals("analyze", request.operation());
        assertEquals("C:/source", request.sourceRoot());
        assertEquals(List.of(), request.classpath());
    }

    @Test
    void rejectsAnUnsupportedProtocolVersion() {
        assertThrows(Protocol.InvalidRequestException.class, () -> Protocol.parseRequest("""
                {"protocolVersion":2,"operation":"analyze","sourceRoot":"C:/source","classpath":[]}
                """));
    }

    @Test
    void rejectsAnUnsupportedOperation() {
        assertThrows(Protocol.InvalidRequestException.class, () -> Protocol.parseRequest("""
                {"protocolVersion":1,"operation":"rewrite","sourceRoot":"C:/source","classpath":[]}
                """));
    }

    @Test
    void responseJsonHasTheStableProtocolFields() {
        String json = Protocol.toJson(Protocol.Response.success(
                List.of("demo/Valid.java"),
                List.of(),
                List.of("demo.Valid"),
                List.of("java.util.List"),
                List.of()
        ));
        JsonObject object = JsonParser.parseString(json).getAsJsonObject();

        assertEquals(Set.of(
                "protocolVersion", "status", "parsedFiles", "parseFailures",
                "declaredTypes", "imports", "diagnostics"
        ), object.keySet());
        assertEquals(1, object.get("protocolVersion").getAsInt());
        assertEquals("ok", object.get("status").getAsString());
    }
}
