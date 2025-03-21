$(document).ready(function() {
  // 삭제 버튼 이벤트
  $('.delete-btn').click(function() {
    const reviewId = $(this).data('review-id');
    deleteReview(reviewId);
  });
});

// 리뷰 삭제
function deleteReview(reviewId) {
  if (!reviewId) {
    console.error('Review Id가 없습니다.');
    return;
  }

  Swal.fire({
    title: '리뷰를 삭제하시겠습니까?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: '삭제',
    cancelButtonText: '취소'
  }).then((result) => {
    if (result.isConfirmed) {
      $.ajax({
        url: `/admin/api/reviews/${reviewId}`,
        type: 'Delete',
        success: function() {
          showAlert('리뷰 삭제가 완료되었습니다.', 'success')
            .then(() => {
              const currentUrl = new URL(window.location.href);
              const currentPage = currentUrl.searchParams.get('page') || 0;

              window.location.href = `/admin/reviewCleanBot?page=${currentPage}`;
            });
        },
        error: function(error) {
          console.log('Error : ', error);
          showAlert('리뷰 삭제가 실패되었습니다.', 'error');
        }
      });
    }
  });
}

function showAlert(title, icon, text = '') {
  return Swal.fire({
      title: title,
      text: text,
      icon: icon,
      confirmButtonText: '확인'
  });
}