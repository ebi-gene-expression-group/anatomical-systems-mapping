def fileToMap(annotation: ammonite.ops.Path) = {
  io.Source.fromFile(annotation.toIO).getLines.map{_.split("\t").toList}.map{case k::v::_ => (k,v)}.toMap
}

@main
def main(annotation: ammonite.ops.Path, fileToAnnotate: ammonite.ops.Path) = {
  val m = fileToMap(annotation)
  io.Source.fromFile(fileToAnnotate.toIO).getLines
  .map{_.split("\t").toList}
  .map{case x::xs => x::m(x)::xs}
  .map{_.mkString("\t")}
  .foreach {
    println _
  }
}
