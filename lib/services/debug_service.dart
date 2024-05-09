class DebugService {
  static pr(String msg, String? functionName) {
    final message = '>>>>>>>> ' + (functionName == null ? msg : "[$functionName] $msg");
    print(message);
  }
}
