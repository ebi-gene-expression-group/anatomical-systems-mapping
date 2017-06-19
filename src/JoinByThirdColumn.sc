def fileToArray(inFile: ammonite.ops.Path) = {
  io.Source.fromFile(inFile.toIO).getLines.map{_.split("\t").toList}
}

@main
def main(inFile: ammonite.ops.Path): Unit = {
  fileToArray(inFile)
  .toList
  .flatMap {
    case x::y::Nil
      => List((x,y,""))
    case x::y::zs
      => zs.flatMap(_.split(" ").map((x,y,_)))
  }
  .groupBy{case (x,y,z) => (y,z)}
  .map{case ((y,z),ts) => (y,z, ts.map(_._1))}
  .map {
    case (y,z,xs)
      => s"${z}\t${y}\t${xs mkString ","}"
  }
  .toList
  .sorted
  .foreach {
    println _
  }
}
