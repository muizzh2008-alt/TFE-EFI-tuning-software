/// Command Formatter & Builder for ECUTuner V61 BLE & Serial Communication
class CommandBuilder {
  static const String prefix = "ECU_SET:";

  // Telemetry Poll
  static List<int> pollTelemetry() => [0x41]; // 'A' in ASCII

  // Chunked Map Flash (Push) - 4 values per chunk (BLE Safe)
  static String setFuelChunk(int row, int chunkIdx, List<int> values) {
    final payload = values.take(4).join(',');
    return "$prefix" "F_CHUNK:$row:$chunkIdx=$payload\n";
  }

  static String setIgnChunk(int row, int chunkIdx, List<int> values) {
    final payload = values.take(4).join(',');
    return "$prefix" "I_CHUNK:$row:$chunkIdx=$payload\n";
  }

  // Chunked Map Read (Pull) - 4 values per chunk
  static String getFuelChunk(int row, int chunkIdx) =>
      "$prefix" "GET_F_CHUNK:$row:$chunkIdx\n";

  static String getIgnChunk(int row, int chunkIdx) =>
      "$prefix" "GET_I_CHUNK:$row:$chunkIdx\n";

  // Engine Settings & Tuning Parameters
  static String setRevLimit(int rpm) => "$prefix" "REV=$rpm\n";
  static String setTdcOffset(int deg) => "$prefix" "TDC_OFFSET=$deg\n";
  static String setFanTemp(int tempC) => "$prefix" "FAN=$tempC\n";
  static String setFanCycle(int cycleMs) => "$prefix" "FAN_CYCLE=$cycleMs\n";
  static String setDriveMode(int mode) => "$prefix" "MODE=$mode\n";
  static String setAls(bool enabled) => "$prefix" "ALS=${enabled ? 1 : 0}\n";
  static String setAeEnabled(bool enabled) => "$prefix" "AE=${enabled ? 1 : 0}\n";
  static String setBoostEnabled(bool enabled) => "$prefix" "BOOST=${enabled ? 1 : 0}\n";
  static String setAeIntensity(int us) => "$prefix" "AE_INT=$us\n";
  static String setBoostPercent(int pct) => "$prefix" "BOOST_PCT=$pct\n";
  static String setPumpIdle(int pct) => "$prefix" "PUMP_IDLE=$pct\n";
  static String setPumpWot(int pct) => "$prefix" "PUMP_WOT=$pct\n";

  // Sensor Calibration
  static String setAfrCalOffset(int offset) => "$prefix" "AFR_CAL_OFFSET=$offset\n";
  static String setAfrCalScale(int scale) => "$prefix" "AFR_CAL_SCALE=$scale\n";
  static String tpsCalStart() => "$prefix" "TPS_CAL_START\n";
  static String tpsCalMax() => "$prefix" "TPS_CAL_MAX\n";

  // Diagnostics & DTC History
  static String getDtcHistory() => "$prefix" "GET_DTC_HISTORY\n";
  static String clearDtcHistory() => "$prefix" "CLEAR_DTC_HISTORY\n";

  // Shift Light
  static String setShiftRpm(int rpm) => "$prefix" "SHIFT_RPM=$rpm\n";
  static String setShiftEnabled(bool enabled) => "$prefix" "SHIFT_EN=${enabled ? 1 : 0}\n";

  // Hardware Output Test (Engine Off Only)
  static String testInjector(int cylIndex) => "$prefix" "TEST_INJ:$cylIndex\n";
  static String testIgnition(int cylIndex) => "$prefix" "TEST_IGN:$cylIndex\n";
  static String testPrimePump() => "$prefix" "TEST_PUMP\n";

  // SD Logging Tools
  static String dumpSdLog() => "$prefix" "DUMP_LOG\n";
  static String clearSdLog() => "$prefix" "CLEAR_LOG\n";
}
