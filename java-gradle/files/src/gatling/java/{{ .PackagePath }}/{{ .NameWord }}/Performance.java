package {{ .Package }}.{{ .NameWord }};

import io.gatling.javaapi.core.ProtocolBuilder;
import io.gatling.javaapi.http.HttpProtocolBuilder;
{{- if eq .KafkaPluginEnabled "true" }}
import org.apache.kafka.clients.producer.ProducerConfig;
import org.galaxio.gatling.kafka.javaapi.KafkaDsl;

import java.util.Map;
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
import org.galaxio.gatling.javaapi.JdbcDsl;

import java.time.Duration;
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
import org.galaxio.gatling.amqp.javaapi.AmqpDsl;
{{- end }}

import static io.gatling.javaapi.http.HttpDsl.http;
import static org.galaxio.gatling.javaapi.SimulationConfig.baseUrl;
import static org.galaxio.gatling.javaapi.SimulationConfig.getStringParam;
import static org.galaxio.gatling.javaapi.SimulationConfig.getIntParam;

public final class Performance {

    public static final HttpProtocolBuilder httpProtocol = http
            .baseUrl(baseUrl())
            .acceptHeader("application/json")
            .contentTypeHeader("application/json")
            .disableFollowRedirect();
{{- if eq .KafkaPluginEnabled "true" }}

    public static ProtocolBuilder kafkaProtocol() {
        return KafkaDsl.kafka()
                .properties(Map.of(
                        ProducerConfig.ACKS_CONFIG, "1",
                        ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, getStringParam("kafkaUrl"),
                        ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer",
                        ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer"
                ));
    }
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}

    public static ProtocolBuilder jdbcProtocol() {
        return JdbcDsl.DB()
                .url(getStringParam("dbUrl"))
                .username(getStringParam("dbUser"))
                .password(getStringParam("dbPassword"))
                .connectionTimeout(Duration.ofSeconds(10))
                .protocolBuilder();
    }
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}

    public static ProtocolBuilder amqpProtocol() {
        return AmqpDsl.amqp()
                .connectionFactory(
                        AmqpDsl.rabbitmq()
                                .host(getStringParam("amqpHost"))
                                .port(getIntParam("amqpPort"))
                                .username(getStringParam("amqpLogin"))
                                .password(getStringParam("amqpPassword"))
                                .vhost("/")
                                .build()
                )
                .replyTimeout(10000L)
                .consumerThreadsCount(1)
                .usePersistentDeliveryMode();
    }
{{- end }}

    private Performance() {
    }
}
