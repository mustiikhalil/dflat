// automatically generated by the FlatBuffers compiler, do not modify
// swiftlint:disable all
// swiftformat:disable all

import FlatBuffers

public enum zzz_DflatGen_ColorV2: Int8, Enum {
  public typealias T = Int8
  public static var byteSize: Int { return MemoryLayout<Int8>.size }
  public var value: Int8 { return self.rawValue }
  case red = 0
  case green = 1
  case blue = 2

  public static var max: zzz_DflatGen_ColorV2 { return .blue }
  public static var min: zzz_DflatGen_ColorV2 { return .red }
}

public struct zzz_DflatGen_BenchDocV2: FlatBufferObject {

  static func validateVersion() { FlatBuffersVersion_1_12_0() }
  public var __buffer: ByteBuffer! { return _accessor.bb }
  private var _accessor: Table

  public static func getRootAsBenchDocV2(bb: ByteBuffer) -> zzz_DflatGen_BenchDocV2 {
    return zzz_DflatGen_BenchDocV2(
      Table(
        bb: bb, position: Int32(bb.read(def: UOffset.self, position: bb.reader)) + Int32(bb.reader))
    )
  }

  private init(_ t: Table) { _accessor = t }
  public init(_ bb: ByteBuffer, o: Int32) { _accessor = Table(bb: bb, position: o) }

  private enum VTOFFSET: VOffset {
    case color = 4
    case title = 6
    case tag = 8
    case priority = 10
    case text = 12
    var v: Int32 { Int32(self.rawValue) }
    var p: VOffset { self.rawValue }
  }

  public var color: zzz_DflatGen_ColorV2 {
    let o = _accessor.offset(VTOFFSET.color.v)
    return o == 0
      ? .red : zzz_DflatGen_ColorV2(rawValue: _accessor.readBuffer(of: Int8.self, at: o)) ?? .red
  }
  public var title: String? {
    let o = _accessor.offset(VTOFFSET.title.v)
    return o == 0 ? nil : _accessor.string(at: o)
  }
  public var titleSegmentArray: [UInt8]? { return _accessor.getVector(at: VTOFFSET.title.v) }
  public var tag: String? {
    let o = _accessor.offset(VTOFFSET.tag.v)
    return o == 0 ? nil : _accessor.string(at: o)
  }
  public var tagSegmentArray: [UInt8]? { return _accessor.getVector(at: VTOFFSET.tag.v) }
  public var priority: Int32 {
    let o = _accessor.offset(VTOFFSET.priority.v)
    return o == 0 ? 0 : _accessor.readBuffer(of: Int32.self, at: o)
  }
  public var text: String? {
    let o = _accessor.offset(VTOFFSET.text.v)
    return o == 0 ? nil : _accessor.string(at: o)
  }
  public var textSegmentArray: [UInt8]? { return _accessor.getVector(at: VTOFFSET.text.v) }
  public static func startBenchDocV2(_ fbb: inout FlatBufferBuilder) -> UOffset {
    fbb.startTable(with: 5)
  }
  public static func add(color: zzz_DflatGen_ColorV2, _ fbb: inout FlatBufferBuilder) {
    fbb.add(element: color.rawValue, def: 0, at: VTOFFSET.color.p)
  }
  public static func add(title: Offset<String>, _ fbb: inout FlatBufferBuilder) {
    fbb.add(offset: title, at: VTOFFSET.title.p)
  }
  public static func add(tag: Offset<String>, _ fbb: inout FlatBufferBuilder) {
    fbb.add(offset: tag, at: VTOFFSET.tag.p)
  }
  public static func add(priority: Int32, _ fbb: inout FlatBufferBuilder) {
    fbb.add(element: priority, def: 0, at: VTOFFSET.priority.p)
  }
  public static func add(text: Offset<String>, _ fbb: inout FlatBufferBuilder) {
    fbb.add(offset: text, at: VTOFFSET.text.p)
  }
  public static func endBenchDocV2(_ fbb: inout FlatBufferBuilder, start: UOffset) -> Offset<
    UOffset
  > {
    let end = Offset<UOffset>(offset: fbb.endTable(at: start))
    return end
  }
  public static func createBenchDocV2(
    _ fbb: inout FlatBufferBuilder,
    color: zzz_DflatGen_ColorV2 = .red,
    titleOffset title: Offset<String> = Offset(),
    tagOffset tag: Offset<String> = Offset(),
    priority: Int32 = 0,
    textOffset text: Offset<String> = Offset()
  ) -> Offset<UOffset> {
    let __start = zzz_DflatGen_BenchDocV2.startBenchDocV2(&fbb)
    zzz_DflatGen_BenchDocV2.add(color: color, &fbb)
    zzz_DflatGen_BenchDocV2.add(title: title, &fbb)
    zzz_DflatGen_BenchDocV2.add(tag: tag, &fbb)
    zzz_DflatGen_BenchDocV2.add(priority: priority, &fbb)
    zzz_DflatGen_BenchDocV2.add(text: text, &fbb)
    return zzz_DflatGen_BenchDocV2.endBenchDocV2(&fbb, start: __start)
  }
}
