package com.example.lab_3;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import pl.leancode.patrol.PatrolJUnitRunner;

// Lớp cầu nối bắt buộc để Patrol phát hiện và chạy các Dart test trong integration_test/.
// Không cần chỉnh sửa tệp này; danh sách test được nạp động từ mã Dart.
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameterized.Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @org.junit.Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
