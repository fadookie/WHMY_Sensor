class DataServer {
  //Data for Setting Up the Flash Socket Server
  int sport = 9002;
  Server myServer;
  int playerStates = 0;
  
  DataServer(PApplet parent) {
    //Setup the socket server
    myServer = new Server(parent, sport);
  }
  
  void update(int player, boolean inAir) {
		println("player " +player+ " in air =" +inAir);
    int bitmask = 1 << player;
    if (inAir) {
      playerStates |= bitmask;
    } else {
      playerStates &= ~bitmask;
    }
    exportData();
  }

  private void exportData()
  {
      //println(padLeft(Integer.toBinaryString(playerStates), 4) );
      myServer.write(playerStates+"\0");
  }
  
  String padLeft(String s, int n) {
    return String.format("%1$" + n + "s", s);  
  }
}
