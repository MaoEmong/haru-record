/// 지도 타일 공급자 설정.
/// 전 세계 공통으로 CARTO Voyager(OSM 데이터의 현대적 렌더링, 키 불필요)를
/// 사용한다. 공급자를 바꿀 때는 이 파일만 수정하면 된다.
/// 데이터 출처: © OpenStreetMap contributors © CARTO
const String mapTileUrlTemplate =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
