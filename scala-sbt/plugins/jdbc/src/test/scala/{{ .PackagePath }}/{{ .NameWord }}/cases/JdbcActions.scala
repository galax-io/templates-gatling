package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.core.Predef._
import org.galaxio.gatling.jdbc.Predef._

object JdbcActions {
  val createTable = exec(
    jdbc("create table")
      .rawSql(
        """create table if not exists mytable(
          |id SERIAL,
          |name varchar(50))""".stripMargin,
      ),
  )
}
