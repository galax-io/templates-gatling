package {{ .Package }}.{{ .NameWord }}

import io.gatling.javaapi.http.HttpDsl.http
import io.gatling.javaapi.http.HttpProtocolBuilder
{{- if eq .KafkaPluginEnabled "true" }}
import org.apache.kafka.clients.producer.ProducerConfig
import org.galaxio.gatling.kafka.javaapi.KafkaDsl
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
import org.galaxio.gatling.javaapi.JdbcDsl
import java.time.Duration
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
import org.galaxio.gatling.amqp.javaapi.AmqpDsl
{{- end }}
import org.galaxio.gatling.javaapi.SimulationConfig.baseUrl
import org.galaxio.gatling.javaapi.SimulationConfig.getStringParam
import org.galaxio.gatling.javaapi.SimulationConfig.getIntParam

object Performance {
    val httpProtocol: HttpProtocolBuilder = http
        .baseUrl(baseUrl())
        .acceptHeader("application/json")
        .contentTypeHeader("application/json")
        .disableFollowRedirect()
{{- if eq .KafkaPluginEnabled "true" }}

    val kafkaProtocol = KafkaDsl.kafka()
        .properties(
            mapOf(
                ProducerConfig.ACKS_CONFIG to "1",
                ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to getStringParam("kafkaUrl"),
                ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to "org.apache.kafka.common.serialization.StringSerializer",
                ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to "org.apache.kafka.common.serialization.StringSerializer",
            )
        )
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}

    val jdbcProtocol = JdbcDsl.DB()
        .url(getStringParam("dbUrl"))
        .username(getStringParam("dbUser"))
        .password(getStringParam("dbPassword"))
        .connectionTimeout(Duration.ofMinutes(2))
        .protocolBuilder()
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}

    val amqpProtocol = AmqpDsl.amqp()
        .connectionFactory(
            AmqpDsl.rabbitmq()
                .host(getStringParam("amqpHost"))
                .port(getIntParam("amqpPort"))
                .username(getStringParam("amqpLogin"))
                .password(getStringParam("amqpPassword"))
                .vhost("/")
                .build()
        )
        .replyTimeout(60000L)
        .consumerThreadsCount(8)
        .usePersistentDeliveryMode()
{{- end }}
}
