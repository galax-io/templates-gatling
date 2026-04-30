package {{ .Package }}.feeders

import org.galaxio.gatling.feeders.RandomUUIDFeeder

object Feeders {
  val messageId = RandomUUIDFeeder("messageId")
}
