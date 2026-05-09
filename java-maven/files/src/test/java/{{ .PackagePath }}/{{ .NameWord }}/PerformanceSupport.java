package {{ .Package }}.{{ .NameWord }};

import scala.concurrent.duration.FiniteDuration;

import java.time.Duration;

public final class PerformanceSupport {

    private PerformanceSupport() {
    }

    public static FiniteDuration toScala(Duration duration) {
        return scala.concurrent.duration.Duration.fromNanos(duration.toNanos());
    }
}
