package {{ .Package }}.{{ .NameWord }}.cases;

import io.gatling.javaapi.core.ChainBuilder;

import static io.gatling.javaapi.core.CoreDsl.exec;
import static io.gatling.javaapi.http.HttpDsl.http;
import static io.gatling.javaapi.http.HttpDsl.status;

public final class HttpActions {

    public static final ChainBuilder getMainPage =
            exec(http("GET /").get("/").check(status().is(200)));

    private HttpActions() {
    }
}
