with import <nixpkgs> {}; {
 exeEnv = stdenv.mkDerivation {
   name = "exs";
   buildInputs = with beam.packages.erlangR20; [
    stdenv
    elixir
    rebar
    rebar3
  ];
  src = ./.;
  
 };
}
