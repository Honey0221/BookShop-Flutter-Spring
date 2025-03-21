import { searchParams } from './bookMng.js';

// 날짜 포맷팅
export function formatDate(dateString) {
    const date = new Date(dateString);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

// sweetAlert2 알림창
export function showAlert(title, icon, text = '') {
    return Swal.fire({
        title: title,
        text: text,
        icon: icon,
        confirmButtonText: '확인'
    });
}

// 엑셀 다운로드 함수
export function downloadExcel() {
    const downloadUrl = `/admin/items/excel-download?` +
        `searchType=${encodeURIComponent(searchParams.searchType)}` +
        `&keyword=${encodeURIComponent(searchParams.keyword)}` +
        `&status=${encodeURIComponent(searchParams.status)}` +
        `&sort=${encodeURIComponent(searchParams.sort)}`;

    window.location.href = downloadUrl;
}

