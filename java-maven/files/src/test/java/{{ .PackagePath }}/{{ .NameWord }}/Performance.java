package {{ .Package }}.{{ .NameWord }};

import io.gatling.javaapi.http.HttpProtocolBuilder;

import static io.gatling.javaapi.http.HttpDsl.http;
import static org.galaxio.gatling.javaapi.SimulationConfig.baseUrl;

public final class Performance {

    public static final HttpProtocolBuilder httpProtocol = http
            .baseUrl(baseUrl())
            .acceptHeader("application/json")
            .contentTypeHeader("application/json")
            .disableFollowRedirect();

    private Performance() {
    }
}
