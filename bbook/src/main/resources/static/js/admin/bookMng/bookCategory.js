// 네가지 카테고리를 로드하는 함수
export function loadCategories(prefix = 'add') {
  return new Promise((resolve, reject) => { // Promise : 비동기 작업을 처리할 때 사용
    ['main', 'mid', 'sub', 'detail'].forEach((type, index, array) => {
      $.get(`/admin/categories/${type}`, function(categories) {
        const select = $(`#${prefix}${type.charAt(0).toUpperCase() + type.slice(1)}Category`);
        select.find('option:gt(0)').remove(); // 기존 옵션을 제거(첫 번째 옵션 제외)
        categories.forEach(category => {
          select.append(`<option value="${category}">${category}</option>`);
        });
        
        // 모두 로드되었으면 Promise 해결
        if (index === array.length - 1) {
          resolve();
        }
      }).fail(reject); // 로드 실패하면 reject
    });
  });
}