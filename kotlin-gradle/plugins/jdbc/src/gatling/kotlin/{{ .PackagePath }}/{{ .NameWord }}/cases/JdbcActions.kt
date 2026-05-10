package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.javaapi.core.ChainBuilder
import io.gatling.javaapi.core.CoreDsl.exec
import org.galaxio.gatling.javaapi.JdbcDsl

object JdbcActions {
    val createTable: ChainBuilder = exec(
        JdbcDsl.jdbc("create table")
            .rawSql("create table if not exists mytable(id SERIAL, name varchar(50))")
    )
}
