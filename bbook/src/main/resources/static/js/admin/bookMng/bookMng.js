import { formatDate, showAlert, downloadExcel } from './utils.js';
import { loadCategories } from './bookCategory.js';
import {
    loadBooks,
    handleSearch,
    handleSearchKeypress,
    handleFilterChange,
    handleSortChange,
    handlePageSizeChange,
    handleEdit,
    handleDelete
} from './bookList.js';
import {
    handleImagePreview,
    handleNumericInput,
    saveBook,
    resetForm,
    initFileInput
} from './bookForm.js';

// 검색 파라미터 기본값
export let searchParams = {
    page: 0,
    size: 10,
    sort: 'id,desc',
    searchType: '',
    keyword: '',
    status: ''
};

$(document).ready(function() {
    // 검색 관련 이벤트
    $('#searchBtn').click(handleSearch);
    $('#searchKeyword').keypress(handleSearchKeypress);
    
    // 필터, 정렬, 페이지 이벤트
    $('#statusFilter').change(handleFilterChange);
    $('#sortBy').change(handleSortChange);
    $('#pageSize').change(handlePageSizeChange);

    // 이미지 미리보기
    $('#addBookImage, #editBookImage').change(handleImagePreview);

    // 가격 입력 필드 검사
    $('#addPrice, #editPrice').on('input', handleNumericInput);

    // 각종 버튼 이벤트
    $('tbody').on('click', '.edit-btn', function() {
      handleEdit($(this).data('id'));
    });

    $('tbody').on('click', '.delete-btn', function() {
      handleDelete($(this).data('id'));
    });

    $('#downloadExcelBtn').click(downloadExcel);
    $('#saveBookBtn, #updateBookBtn').click(saveBook);

    // 모달 이벤트
    $('#addBookModal').on('show.bs.modal', function() {
        loadCategories('add');
    });

    $('#addBookModal').on('hidden.bs.modal', function() {
      resetForm('#addBookForm');
    });

    $('#editBookModal').on('hidden.bs.modal', function() {
      resetForm('#editBookForm');
    });

    initFileInput('addBookImage', 'addImagePreview');
    initFileInput('editBookImage', 'editImagePreview');
    loadBooks();
});
