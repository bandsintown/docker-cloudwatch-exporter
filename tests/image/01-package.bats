@test "'java' should be present" {
  run java -version
  [ $status -eq 0 ]
}