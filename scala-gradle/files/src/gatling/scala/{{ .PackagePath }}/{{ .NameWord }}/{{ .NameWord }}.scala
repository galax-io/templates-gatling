package {{ .Package }}

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.annotation.nowarn
{{- if eq .KafkaPluginEnabled "true" }}
import org.apache.kafka.clients.producer.ProducerConfig
import org.galaxio.gatling.kafka.Predef.kafka
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
import org.galaxio.gatling.jdbc.Predef._
import scala.concurrent.duration.DurationInt
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
import org.galaxio.gatling.amqp.Predef._
{{- end }}
import org.galaxio.gatling.config.SimulationConfig._
package object {{ .NameWord }} {

  val httpProtocol = http
    .baseUrl(baseUrl)
    .acceptHeader("application/json")
    .contentTypeHeader("application/json")
    .disableFollowRedirect
{{- if eq .KafkaPluginEnabled "true" }}

  @nowarn("cat=deprecation")
  val kafkaProtocol = kafka
    .topic(getStringParam("kafkaTopic"))
    .properties(
      Map(
        ProducerConfig.ACKS_CONFIG                   -> "1",
        ProducerConfig.BOOTSTRAP_SERVERS_CONFIG      -> getStringParam("kafkaUrl"),
        ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG   -> "org.apache.kafka.common.serialization.StringSerializer",
        ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringSerializer",
      ),
    )
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}

  val jdbcProtocol = DB
    .url(getStringParam("dbUrl"))
    .username(getStringParam("dbUser"))
    .password(getStringParam("dbPassword"))
    .connectionTimeout(2.minutes)
    .protocolBuilder
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}

  val amqpProtocol = amqp
    .connectionFactory(
      rabbitmq
        .host(getStringParam("amqpHost"))
        .port(getIntParam("amqpPort"))
        .username(getStringParam("amqpLogin"))
        .password(getStringParam("amqpPassword"))
        .vhost("/"),
    )
    .replyTimeout(60000)
    .consumerThreadsCount(8)
    .usePersistentDeliveryMode
{{- end }}

}
