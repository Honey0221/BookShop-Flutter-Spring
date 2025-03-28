import { searchParams } from './bookMng.js';
import { loadCategories } from './bookCategory.js';
import { showAlert, formatDate } from './utils.js';

// 도서 조회
export function loadBooks() {
    $.ajax({
        url: '/admin/items/list',
        type: 'GET',
        data: searchParams,
        success: function(response) {
            updateTable(response.content);
            updatePagination(response);
        },
        error: function() {
            showAlert('데이터 조회 실패', 'error');
        }
    });
}

// 표 업데이트
function updateTable(books) {
    const tbody = $('tbody');
    tbody.empty();

    books.forEach(function(book) {
        const tr = `
            <tr>
                <td class="small">${book.id}</td>
                <td class="text-start">${book.title}</td>
                <td class="small">${book.author}</td>
                <td class="small">${book.publisher}</td>
                <td class="small">${book.stock}</td>
                <td class="small">${book.price.toLocaleString()}</td>
                <td>
                    <span>${book.bookStatus === 'SELL' ? '판매중' : '품절'}</span>
                </td>
                <td class="small">${formatDate(book.createdAt)}</td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button type="button" class="btn btn-sm btn-primary edit-btn" data-id="${book.id}">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-danger delete-btn" data-id="${book.id}">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
        tbody.append(tr);
    });

    $('.edit-btn').click(function() {
      handleEdit($(this).data('id'));
    });

    $('.delete-btn').click(function() {
      handleDelete($(this).data('id'));
    });
}

// 페이징 생성
function createPageItem(page, disabled, iconName) {
    return `
        <li class="page-item ${disabled ? 'disabled' : ''}">
            <a class="page-link" href="#" data-page="${page}">
                <i class="fas fa-${iconName}"></i>
            </a>
        </li>
    `;
}

// 페이징 업데이트
function updatePagination(response) {
    const pagination = $('.pagination');
    pagination.empty();

    // 처음 버튼
    pagination.append(createPageItem(0, response.first, 'angle-double-left'));

    // 이전 페이지 그룹
    const startPage = Math.floor(response.number / 10) * 10;
    if (startPage > 0) {
        pagination.append(createPageItem(startPage - 1, false, 'angle-left'));
    }

    // 페이지 번호
    for (let i = startPage; i < startPage + 10 && i < response.totalPages; i++) {
        pagination.append(`
            <li class="page-item ${response.number === i ? 'active' : ''}">
                <a class="page-link" href="#" data-page="${i}">${i + 1}</a>
            </li>
        `);
    }

    // 다음 페이지 그룹
    if (startPage + 10 < response.totalPages) {
        pagination.append(createPageItem(startPage + 10, false, 'angle-right'));
    }

    // 마지막 버튼
    pagination.append(createPageItem(response.totalPages - 1, response.last, 'angle-double-right'));

    attachPaginationEvents();
}

// 페이지 클릭
function attachPaginationEvents() {
    $('.page-link').click(function(e) {
        e.preventDefault();
        const page = $(this).data('page');
        if (page !== undefined && !$(this).parent().hasClass('disabled')) {
            searchParams.page = page;
            loadBooks();
        }
    });
}

// 검색 버튼
export function handleSearch() {
    searchParams.searchType = $('#searchType').val();
    searchParams.keyword = $('#searchKeyword').val();
    searchParams.page = 0;
    loadBooks();
}

// 엔터누르면 검색 실행
export function handleSearchKeypress(e) {
    if (e.which === 13) {
        $('#searchBtn').click();
    }
}

// 필터 값 변경
export function handleFilterChange() {
    searchParams.status = $(this).val();
    searchParams.page = 0;
    loadBooks();
}

// 정렬 값 변경
export function handleSortChange() {
    searchParams.sort = $(this).val();
    searchParams.page = 0;
    loadBooks();
}

// 페이지 크기 변경
export function handlePageSizeChange() {
    searchParams.size = $(this).val();
    searchParams.page = 0;
    loadBooks();
}

// 도서 수정
export function handleEdit(bookId) {
    // 모달 표시하기 전에 카테고리와 도서 정보를 로드
    Promise.all([
        loadCategories('edit'),
        new Promise((resolve, reject) => {
            $.get(`/admin/items/${bookId}`)
                .done(resolve)
                .fail(reject);
        })
    ])
    .then(([_, book]) => {
        // 수정 폼 필드 채우기
        $('#editBookId').val(bookId);
        $('#editTitle').val(book.title);
        $('#editAuthor').val(book.author);
        $('#editPublisher').val(book.publisher);
        $('#editPrice').val(book.price);
        $('#editStock').val(book.stock);
        $('#editMainCategory').val(book.mainCategory);
        $('#editMidCategory').val(book.midCategory);
        $('#editSubCategory').val(book.subCategory);
        $('#editDetailCategory').val(book.detailCategory);
        $('#editDescription').val(book.description);

        // 이미지 미리보기
        if (book.imageUrl) {
            $('#editImagePreview').attr('src', book.imageUrl).show();
            $('#editBookModal .custom-file-upload').html(
            '<i class="fas fa-check"></i> 기존 이미지');
        } else {
            $('#editImagePreview').hide();
            $('#editBookModal .custom-file-upload').html(
            '<i class="fas fa-cloud-upload-alt"></i> 이미지를 선택하거나 여기에 드래그하세요');
        }

        $('#editBookModal').modal('show');
    }).catch(error => {
        console.error('데이터 로드 실패:', error);
        showAlert('데이터 로드에 실패했습니다.', 'error');
    });
}

// 도서 삭제
export function handleDelete(bookId) {
  Swal.fire({
    title: '삭제 확인',
    text: '정말로 이 도서를 삭제하시겠습니까?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: '삭제',
    cancelButtonText: '취소'
  }).then((result) => {
    if (result.isConfirmed) {
      $.ajax({
        url: `/admin/items/${bookId}`,
        type: 'Delete',
        success: function() {
          showAlert('삭제 완료', 'success', '도서가 성공적으로 삭제되었습니다.')
            .then(() => loadBooks());
        },
        error: function() {
          showAlert('삭제 실패', 'error', '도서 삭제 중 오류가 발생했습니다.');
        }
      });
    }
  });
}
