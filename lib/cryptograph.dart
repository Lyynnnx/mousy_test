class Cryptograph {
  String alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

String decryptIp(String encoded) {
  List<String> decodedParts = [];
  if(encoded.length%2!=0){
    encoded+="V";
  }

  for (int i = 0; i < encoded.length; i += 2) {
    String firstChar = encoded[i];
    String secondChar = encoded[i + 1];

    int num = alphabet.indexOf(firstChar) * alphabet.length + alphabet.indexOf(secondChar);
    decodedParts.add(num.toString());
  }

  return decodedParts.join(".");
}
}