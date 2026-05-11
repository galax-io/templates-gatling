package {{ .Package }}.{{ .NameWord }}.cases;

import io.gatling.javaapi.core.ChainBuilder;
import org.galaxio.gatling.javaapi.JdbcDsl;

import static io.gatling.javaapi.core.CoreDsl.exec;

public final class JdbcActions {

    public static final ChainBuilder createTable =
            exec(JdbcDsl.jdbc("create table")
                    .rawSql("create table if not exists mytable(id SERIAL, name varchar(50))"));

    private JdbcActions() {
    }
}
