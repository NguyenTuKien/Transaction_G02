# Concurrency Control & Deadlock in Transaction Management

---
## 1. Introduction
> ### Bài toán: Làm sao để có thể đồng bộ hóa các transaction diễn ra đồng thời mà vẫn đảm bảo tính nhất quán của dữ liệu (Consistency) và tính cô lập (Isolation) của hệ thống?

Khi nhiều transaction cùng truy cập và thao tác trên cùng một dữ liệu, có thể xảy ra các vấn đề như:
- **Lost Update**: Khi hai transaction cùng đọc và cập nhật một dữ liệu, có thể dẫn đến việc một transaction ghi đè lên kết quả của transaction khác mà không biết.
    - Ví dụ: Hai người cùng đặt mua vé máy bay (ghế còn lại = 100).
    
        | Thời gian | T1( A mua 10 vé) | T2 (B mua 20 vé)| 
        | --- | --- | --- |
        | t1 | Read(x) -> x = 100 | |
        | t2 | | Read(x) -> x = 100 |
        | t3 | x=100-10=90, write(x) = 90 | |
        | t4 | | x=100-20=80, write(x) = 80 |

    &rarr; Kết quả cuối: x = 80

    &rArr; T2 đọc x=100 từ trước khi T1 ghi, nên T2 không biết T1 đã trừ 10 rồi. T2 ghi đè lên kết quả của T1. Hệ thống thấy còn 80 ghế, nhưng thực tế đã bán ra 10 + 20 = 30 vé, đúng ra phải còn 70 ghế.
    
    &rArr; Kết quả của T1 bị mất hoàn toàn – như thể T1 chưa từng chạy.
-  **Inconsistent Retrieval**: Khi một transaction đọc dữ liệu trong khi một transaction khác đang cập nhật dữ liệu đó, có thể dẫn đến việc đọc được dữ liệu không nhất quán.
    - 🡪 Ví dụ: T1 đang kiểm tra tổng vé (đọc nhiều lần để tính toán), T2 đang bán vé.
    
        | Thời gian | T1( Kiểm toán- đọc 2 lần) | T2(bán 20 vé) |
        | --- | --- | --- |
        | t1 | Read(x) -> x = 100 | |
        | t2 | | Read(x) -> x = 100 |
        | t3 | x=100-10=90, write(x) = 90 | |
        | t4 | | x=100-20=80, write(x) = 80 |

    ***Vấn đề***: T1 chưa làm gì cả, chỉ đọc thôi, nhưng trong cùng một lần làm việc (cùng một giao tác) lại thấy hai con số khác nhau: lúc 100, lúc 80. &rArr; Báo cáo không tin cậy.

---
## 2. Tính tuần tự của các transaction
Trong CSDL tập trung, một lịch sử thực thi (history/schedule) là đúng đắn nếu nó tương đương với một lịch sử nối tiếp nào đó – tức là có thể tuần tự hóa (serializable). Trong CSDL phân tán, vấn đề phức tạp hơn vì có nhiều node.

Có hai loại lịch sử thực thi:
- Lịch sử cục bộ (Local History): Chỉ xem xét các transaction trong một site riêng lẻ.
- Lịch sử toàn cục (Global History): Kết hợp tất cả các lịch sử cục bộ của toàn hệ thống.

Để đảm báo được tính tuần tự toàn cục, cần đảm bảo 2 điều kiện:
- Mỗi lịch sử cục bộ phải có thể tuần tự hóa → Tuần tự hóa cục bộ (local serializability).
- Hai phép toán xung đột nhau phải có cùng thứ tự tương đối trong ***TẤT CẢ*** các lịch sử cục bộ nơi chúng xuất hiện cùng nhau → Tuần tự hóa toàn cục (global serializability).

Ví dụ: X chuyển 100 cho Y (NonGlobal Serializable)
| Thời gian | T1 | T2 |
| --- | --- | --- |
| t1 | Read(x) | |
| t2 | x ← x - 100 | |
| t3 | Write(x) | |
| t4 | | Read(x) | 
| t5 | | Read(y) |
| t6 | | Commit |
| t7 | Read(y) | |
| t8 | y ← y + 100 | | 
| t9 | Write(y) | | 
| t10 | Commit | |

Với X được lưu ở Site 1, Y ở Site 2.

Ta có LH1, LH2 là 2 thứ tự thực thi của T1 và T2:
- LH1: Read1(X), Write1(X), Read2(X).
- LH2: Read2(Y), Read1(Y), Write1(Y).

Mỗi lịch sử cục bộ đều có thể tuần tự hóa, nhưng thứ tự toàn cục mâu thuẫn: T1 trước T2 ở Site 1, T2 trước T1 ở Site 2 → Không tuần tự hóa toàn cục!

***Hậu quả thực tế:***
Giả sử ban đầu x = 500,y=500, y = 500 ,y=500, tổng = 1000$. 

T2 đọc x sau khi T1 đã trừ → thấy x = 400$

T2 đọc y trước khi T1 cộng → thấy y = 500$

T2 tính tổng = 400 + 500 = 900$ 

Nhưng thực tế tổng vẫn phải là 1000$ vì T1 chỉ chuyển tiền, không tạo ra hay xóa tiền. T2 đọc ra con số sai vì bắt gặp T1 đang làm dở.

---
## 3. Concurrency Control Algorithms
Được chia thành 2 loại:
- **Pessimistic Concurrency Control**: Giả định rằng sẽ có xung đột xảy ra, do đó sử dụng các cơ chế khóa để ngăn chặn xung đột. Ví dụ: Two-Phase Locking (2PL), Timestamp Ordering (TO).
- **Optimistic Concurrency Control**: Giả định rằng sẽ không có xung đột xảy ra, do đó cho phép các transaction thực hiện đồng thời và kiểm tra xung đột khi commit. Nếu phát hiện xung đột, transaction sẽ bị rollback và thực hiện lại. Ví dụ: Locking và Timestamp ordering.

---
## 4 Two-Phase Locking (2PL)
### Locking-based protocol
- Một transaction gửi tín hiện muốn thực hiện hành động bằng cách yêu cầu một loại khóa (Shared Lock hoặc Exclusive Lock) trên dữ liệu từ người lập lịch (scheduler or lock manager).
- Khóa có 2 loại: 
  - Read Lock (or Shared Lock): Cho phép nhiều transaction đọc dữ liệu cùng lúc nhưng không cho phép cập nhật.
  - Write Lock (or Exclusive Lock): Chỉ cho phép một transaction đọc hoặc cập nhật dữ liệu tại một thời điểm.
- 2 khóa đọc - ghi hoặc ghi - ghi trên cùng một dữ liệu được gọi là xung đột (conflict).

---
### 2PL (Two-Phase Locking)
- Một transaction phải tuân theo 2 giai đoạn:
  - Giai đoạn tăng dần (Growing Phase): Transaction có thể yêu cầu khóa nhưng không được phép giải phóng khóa.
  - Giai đoạn giảm dần (Shrinking Phase): Transaction có thể giải phóng khóa nhưng không được phép yêu cầu khóa mới.
- 2PL đảm bảo tính tuần tự của các transaction, nhưng có thể dẫn đến deadlock nếu hai hoặc nhiều transaction chờ nhau giải phóng khóa.
- Tuy nhiên, trong quá trình thực thi, transaction cần thay đổi khóa vì mục đích cập nhật dữ liệu, khi đó quá trình ***Lock Conversion*** sẽ diễn ra, tức là transaction sẽ phải giải phóng khóa cũ và yêu cầu khóa mới theo nguyên tắc:
    - Upgrading a Lock: Từ Read Lock sang Write Lock, chỉ được thực thi trong Growing Phase.
    - Downgrading a Lock: Từ Write Lock sang Read Lock, chỉ được thực thi trong Shrinking Phase.

<div style="text-align: center;">
  <img src="https://media.geeksforgeeks.org/wp-content/uploads/20250109131143310074/2pl_locking.webp" alt="2PL Phases" width="1000">
</div>

- ***Lock point***: Điểm trong lịch sử thực thi của transaction mà tại đó transaction đã nắm giữ tất cả các khóa cần thiết để thực hiện các hành động của mình. Sau lock point, transaction sẽ không yêu cầu thêm khóa nào nữa và sẽ bắt đầu giải phóng khóa.

---
### Centrailized 2PL
- Tất cả các transaction gửi yêu cầu khóa đến một lock manager trung tâm.
- Các yêu cầu lock đều được gửi tới bộ lập lịch trung tâm.
Chào Kiên, chúng ta hãy cùng ráp chuẩn form ví dụ thư viện đó vào luồng xử lý cho dự án web đặt vé xem phim nhé. Cách diễn đạt này cực kỳ phù hợp và rành mạch để đưa vào tài liệu phân tích thiết kế:

- **Ví dụ:** Hãy tưởng tượng một hệ thống đặt vé nơi nhiều người dùng có thể truy cập đồng thời để chọn ghế. Mỗi quá trình đặt vé được coi là một giao dịch (transaction). Dưới đây là cách Giao thức 2PL hoạt động, bao gồm cả cơ chế nâng cấp khóa và điểm khóa (lock point):
    - **Khách hàng A muốn:**
        - Kiểm tra trạng thái của ghế "Vip-A1" xem có ai đặt chưa.
        - Đặt giữ chỗ ghế "Vip-A1" nếu nó còn trống.
        - Cập nhật trừ đi số lượng vé còn lại của suất chiếu 20:00.

    - **Giai đoạn Mở rộng (Growing Phase - Thu thập khóa):**
        - Khách hàng A khóa bản ghi ghế "Vip-A1" bằng một **khóa chia sẻ (S)** để đọc và kiểm tra trạng thái ghế.
        - Sau khi xác nhận ghế chưa có ai mua, Khách hàng A **nâng cấp (upgrades)** khóa (S) đó lên thành **khóa độc quyền (X)** để thực sự tiến hành giữ chỗ và đổi trạng thái ghế.
        - Tiếp đó, Khách hàng A xin cấp thêm **khóa độc quyền (X)** cho bản ghi thông tin "Suất chiếu 20:00" để chuẩn bị cập nhật số lượng vé.
    - **Điểm khóa (Lock Point):**
        - Một khi Khách hàng A đã lấy đủ tất cả các khóa cần thiết (khóa X trên ghế Vip-A1 và khóa X trên suất chiếu 20:00), giao dịch chính thức chạm tới *Lock Point*. Kể từ giây phút này trở đi, hệ thống tuyệt đối không cho phép Khách hàng A xin thêm bất kỳ khóa nào khác nữa.
    - **Giai đoạn Thu hẹp (Shrinking Phase - Giải phóng khóa):**
        - Khách hàng A hoàn tất việc trừ đi 1 vé ở suất chiếu và **giải phóng (releases)** khóa trên bản ghi "Suất chiếu 20:00".
        - Khách hàng A hoàn tất việc lưu trạng thái ghế thành "Đã bán" và **giải phóng (releases)** khóa độc quyền (X) trên ghế "Vip-A1", kết thúc giao dịch an toàn.
```
[Vai trò Site]               [Vai trò Phối Hợp]           [Vai trò Quản Lý Khóa]
(Bên chứa Data)              (Bên xử lý App)              (Bên cấp Khóa)
       |                                |                              |
       |                                |                              |
       |=== PHA MỞ RỘNG (GROWING PHASE) ===============================|
       |                                |                              |
       |                                |      1. Lock Request         |
       |                                |----------------------------->|
       |                                |   (Yêu cầu gom khóa S/X)     |
       |                                |                              |
       |                                |                              |
       |                                |       2. Lock Granted        |
       |                                |<-----------------------------|
       |                                |      (Đã cấp đủ khóa)        |
       |                                |                              |
       |                                |                              |
       |=== ĐIỂM KHÓA (LOCK POINT) ====================================|
       |                                |                              |
       |                                |                              |
       |         3. Operation           |                              |
       |<-------------------------------|                              |
       | (Thực hiện lệnh CSDL)          |                              |
       |                                |                              |
       |                                |                              |
       |     4. End of Operation        |                              |
       |------------------------------->|                              |
       | (Dữ liệu đã lưu, báo kết quả)  |                              |
       |                                |                              |
       |                                |                              |
       |=== PHA THU HẸP (SHRINKING PHASE) =============================|
       |                                |                              |
       |                                |    5. Release Locks          |
       |                                |----------------------------->|
       |                                |   (Nhả toàn bộ khóa ra)      |
       |                                |                              |
```
- Ưu điểm: Đơn giản, dễ hiểu, đảm bảo tính tuần tự.
- Nhược điểm: Có thể dẫn đến deadlock, hiệu suất thấp nếu có nhiều transaction cạnh tranh tài nguyên, nếu node trung tâm bị lỗi thì toàn hệ thống bị ảnh hưởng.
---
### Distributed 2PL
- 2PL scheduler được đặt ở từng site. Mỗi scheduler quản lý các transaction và khóa trên site của mình.
- Một transaction có thể đọc bất kì bản sao nào item x bằng cách lấy khóa đọc trên một trong các bản sao đó. Tuy nhiên, để cập nhật item x, transaction phải lấy khóa ghi trên tất cả các bản sao của x.
- Ưu điểm: Không có điểm lỗi đơn (no single point of failure), tải được phân tán đều.
- Nhược điểm: Phức tạp hơn, cần giao thức phân tán để phát hiện deadlock toàn cục.
---
## 5. Deadlock
Deadlock (khóa chết) xảy ra khi một giao tác bị khóa và sẽ tiếp tục bị khóa mãi mãi nếu không có sự can thiệp từ bên ngoài.

***Nguyên nhân:*** Cần có 4 yếu tố sau đây:
- Mutual Exclusion (Loại trừ lẫn nhau): Ít nhất một tài nguyên phải ở trạng thái không chia sẻ được, tức là chỉ có thể được sử dụng bởi một giao tác tại một thời điểm.
- Hold and Wait (Giữ và chờ): Một giao tác đang giữ ít nhất một tài nguyên và đang chờ để có được thêm tài nguyên mà hiện đang bị giữ bởi các giao tác khác.
- No Preemption (Không thể tước đoạt): Tài nguyên không thể bị tước đoạt từ một giao tác đang giữ nó, nghĩa là tài nguyên chỉ có thể được giải phóng tự nguyện bởi giao tác đang giữ nó sau khi hoàn thành công việc của mình.
- Circular Wait (Chờ vòng tròn): Có một tập hợp các giao tác {T1, T2, ..., Tn} sao cho T1 đang chờ tài nguyên mà T2 đang giữ, T2 đang chờ tài nguyên mà T3 đang giữ, ..., và Tn đang chờ tài nguyên mà T1 đang giữ, tạo thành một vòng chờ.

Tác động của deadlock: Giao tác sẽ bị treo vô thời hạn, không thể hoàn thành công việc của mình, dẫn đến giảm hiệu suất hệ thống.

#### Các giải pháp xử lý deadlock:
**Deadlock Avoidance**: 
- Truy cập tài nguyên theo một thứ tự cố định để tránh vòng chờ.
- Sử dụng khóa cấp thấp và cách ly tài nguyên để giảm khả năng xảy ra deadlock.

**Wait-for graph**: Một đồ thị có các node là giao tác và có một cạnh từ T1 đến T2 nếu T1 đang chờ tài nguyên mà T2 đang giữ. Nếu đồ thị có chu trình, thì có deadlock.

<div style="text-align: center;">
  <img src="https://media.geeksforgeeks.org/wp-content/cdn-uploads/transaction1.png" alt="Wait-for Graph" width="600">
</div>

- WFG cũng phân ra thành 2 loại: Local WFG (chỉ xem xét giao tác trên một site) và Global WFG (xem xét tất cả giao tác trên toàn hệ thống).
- Ví dụ: T1, T2 chạy tại Site 1; T3, T4 chạy tại Site 2:
    - T3 chờ khóa từ T4
    - T4 chờ khóa từ T1
    - T1 chờ khóa từ T2
    - T2 chờ khóa từ T3
- Kết quả:
    - WFG cục bộ: Site 1: T1 &rarr; T2 (không phát hiện deadlock), Site 2: T3 &rarr; T4 (không phát hiện deadlock).
    - WFG toàn cục: T1 &rarr; T2 &rarr; T3 &rarr; T4 &rarr; T1 (phát hiện deadlock).

&rArr; Deadlock cục bộ có thể không phát hiện được deadlock toàn cục, do đó cần phải xây dựng WFG toàn cục để đảm bảo phát hiện deadlock.

**Deadlock Detection**:
Để ngăn ngừa deadlock, ta cho phép chúng xảy ra và phát hiện giải quyết chúng:
- Các giao tác được phép chờ đợi tự do.
- Sử dụng WFG và tìm chu trình.

***Phát hiện Deadlock tập trung:***
- Một size được chỉ định làm bộ phát hiện deadlock trung tâm, thu thập thông tin về các giao tác và tài nguyên từ tất cả các site, xây dựng WFG toàn cục và kiểm tra chu trình định kỳ.
- Mỗi bộ lên lịch định kì gửi thông tin về các giao tác đang chờ và tài nguyên mà chúng đang giữ về bộ phát hiện deadlock trung tâm.
- Site trung tâm gộp toàn bộ thông tin để xây dựng WFG toàn cục và kiểm tra chu trình. Nếu phát hiện chu trình, nó sẽ chọn một giao tác để hủy bỏ (rollback) để giải phóng tài nguyên và phá vỡ vòng chờ.
- Tradeoff: 
    - Gửi quá thường xuyên: Chi phí cao, phát hiện nhanh.
    - Gửi quá thưa: Chi phí thấp, phát hiện chậm.

&rArr; Centralized Deadlock Detection được đề xuất trong hệ thống Distributed INGRES.

***Phát hiện Deadlock phân cấp***
- Xây dựng một cây phân cấp các bộ phát hiện deadlock (Deadlock Detectors – DD).
- Các DD ở lá (leaf) tương ứng với từng site.
- Các DD cha nhận WFG từ các DD con và gộp lại.
- DD gốc (root) có cái nhìn toàn cục và phát hiện deadlock toàn cục.
```
DD0X
|- DD11
|  |- DD21 (Site 1)
|  |- DD22 (Site 2)
|- DD12
   |- DD23 (Site 3)
   |- DD24 (Site 4)
```
Ví dụ với 4 site: DD21 (Site 1), DD22 (Site 2), DD23 (Site 3), DD24 (Site 4) → DD11 và DD12 → DD0x (gốc).

***Phát hiện Deadlock phân tán***

Các site hợp tác với nhau trong việc phát hiện deadlock, không có site trung tâm.

Cơ chế hoạt động:
- Bước 1: Mỗi site xây dựng WFG cục bộ có bổ sung, thêm các cạnh ngoại (external edges) biểu diễn chu trình deadlock tiềm năng từ các site khác.
- Bước 2: Ghép các cạnh ngoại với các cạnh thông thường trong WFG.
- Bước 3: Truyền WFG cục bộ này cho các site khác.

Mỗi bộ phát hiện deadlock cục bộ:
- Tìm chu trình KHÔNG có cạnh ngoại → Deadlock cục bộ, giải quyết tại chỗ.
- Tìm chu trình CÓ cạnh ngoại → Deadlock toàn cục tiềm năng, chuyển thông tin cho site tiếp theo.

***So sánh***
| | Centralized | Hirerarchical | Distributed |
| --- | --- | --- | --- |
| Tổ chức | Một site trung tâm | Cây phân cấp | Ngang hàng |
| Điểm lỗi đơn | Có (site trung tâm) | Có (từng nhánh) | Không |
| Độ phức tạp | Đơn giản | Trung bình | Phức tạp |
| Hiệu suất | Kém khi tải lớn | Trung bình | Tốt |

**Deadlock Prevention**
***Wait-Die Scheme:***
- Các transaction cũ cho phép chờ (wait), các transaction mới bị hủy (die).
- Ví dụ: Có 2 transacntion A = 10, B = 20 (số càng nhỏ thì càng cũ):
    - A chờ B → A được phép chờ vì A cũ hơn B.
    - B chờ A → B bị hủy vì B mới hơn A.
***Wound-Wait Scheme:***
- Các transaction cũ bị hủy (wound), các transaction mới cho phép chờ (wait).
- Ví dụ: Có 2 transacntion A = 10, B = 20 (số càng nhỏ thì càng cũ):
    - A chờ B → A bị hủy vì A cũ hơn B.
    - B chờ A → B được phép chờ vì B mới hơn A.
***So sánh***

| Wait-Die | Wound-Wait |
| --- | --- |
| Nó dựa trên kĩ thuật chống phủ đầu | Nó dựa trên kĩ thuật phủ đầu |
| Transaction cũ phải chờ cái mới giải phóng tài nguyên của nó | Transaction cũ không bao giờ phải chờ transaction mới |   
| Số lượng hủy và rollbacks có thể cao hơn vì kĩ thuật này | Số lượng hủy và rollbacks có thể thấp hơn vì kĩ thuật này | 

---
## 6. Timestamp Ordering (TO)
Thay vì dùng khóa, TO gán cho mỗi giao tác một dấu thời gian (timestamp) duy nhất toàn cục. Các thao tác xung đột được giải quyết theo thứ tự timestamp.

***Cơ chế:***
- Giao tác Ti được gán timestamp ts(Ti) – duy nhất và toàn cục.
- TM gắn timestamp vào tất cả các thao tác do giao tác phát ra.
- Mỗi mục dữ liệu x có: 
    - rts(x) = timestamp đọc lớn nhất
    - wts(x) = timestamp ghi lớn nhất.
- Các thao tác xung đột được thực thi theo thứ tự timestamp.

***Đặc điểm:***
- Ưu tiên giao tác cũ hơn, giảm khả năng xảy ra deadlock.
- Có thể quả lý conflict ngay khi tranction phát sinh thay vì phải chờ đến khi commit.
- Đảm bảo tính tuần tự.

---
### 6.1. Basic Timestamp Ordering
***Quy tắc xử lý:***

| | Đọc x | Ghi x | 
| --- | --- | --- |
| Chấp nhận | ts(Ti) >= wts(x) | ts(Ti) >= rts(x) và ts(Ti) >= wts(x) |
| Từ chối | ts(Ti) < wts(x) | ts(Ti) < rts(x) hoặc ts(Ti) < wts(x) |

Khi 1 transaction bị từ chối, nó sẽ bị hủy (abort) và có thể được thực hiện lại với một timestamp mới.

---
### 6.2. Conservative Timestamp Ordering
Basic TO có thể dẫn đến nhiều giao tác bị hủy do xung đột. Conservative TO cố gắng giảm thiểu điều này bằng cách kiểm tra trước tất cả các tài nguyên mà giao tác sẽ truy cập trước khi bắt đầu thực hiện. Nếu có bất kỳ xung đột nào, giao tác sẽ không bắt đầu và có thể được lên lịch lại sau.

Đảm bảo không có transaction nào có timestamp nhỏ hơn có thể đến bộ lên lịch sau thao tác hiện tại.

***So sánh Basic TO và Conservative TO:***
| | Basic TO | Conservative TO |
| --- | --- | --- |
| Cơ chế | Kiểm tra xung đột khi thực hiện thao tác | Kiểm tra xung đột trước khi bắt đầu giao tác (sử dụng trì hoãn) |
| Tỷ lệ hủy | Cao hơn do xung đột | Thấp hơn do kiểm tra trước |
| Hiệu suất | Có thể thấp nếu có nhiều xung đột | Thường cao hơn trong môi trường có nhiều xung đột |

---
### 6.3. Multiversion Concurrency Control (MVCC)
MVCC là cơ chế không thay đổi giá trị cũ trong database mà tạo ra một phiên bản mới mỗi khi có cập nhật. Mỗi phiên bản được gán một timestamp, cho phép các transaction đọc dữ liệu mà không bị chặn bởi các transaction ghi.

***Nguyên tắc:***
- Mỗi lần ghi Wi(x) tạo ra 1 phiên bản mới x_i với timestamp ts(Ti).
- Khi đọc Ri(x), giao tác sẽ đọc phiên bản phù hợp mà không cần chờ.

***Quy tắc đọc:***
Read(x) được phiên dịch thành đọc trên 1 phiên bản cụ thể xv cũa x với ts(xv) <= ts(Ti) và không có phiên bản nào khác của x với ts(xk) > ts(Ti) và ts(xk) <= ts(Ti) (tức là đọc nhiên bản mới nhất của x trước khi giao tác bắt đầu).

***Quy tắc ghi:***
Wi(x) được chấp nhận nếu bộ xử lý chưa xử lý bất kì thao tác Rj(xv) nào thỏa mãn ts(Tj) > ts(Ti) và ts(xv) <= ts(Ti). Nếu có, Wi(x) bị từ chối và giao tác Ti bị hủy.

---
## 7. Optimistic Concurrency Control
Optimistic Concurrency Control (OCC) là một phương pháp quản lý đồng thời mà giả định rằng các giao tác sẽ không xung đột với nhau. Thay vì sử dụng khóa để ngăn chặn xung đột, OCC cho phép các giao tác thực hiện đồng thời và kiểm tra xung đột khi chúng cố gắng commit.

So sánh:
| Bi quan (Pessimistic) | Lạc quan (Optimistic) |
| --- | --- |
| Giả định sẽ có xung đột | Giả định sẽ không có xung đột |
| Validate &rarr; Read &rarr; Compute &rarr; Write | Read &rarr; Compute &rarr; Write &rarr; Validate |

Mô hình thực thi:
- Giao tác Ti được chia thành các giao tác nhỏ hơn (subtransaction) để thực hiện các thao tác trên dữ liệu tại các site j.
- Các subtransaction chạy độc lập từng site cho đến khi kết thúc pha đọc.
- Tất cả các subtrans được gán timestamp tại cuối pha đọc.
- Kiểm tra hợp lệ (validation) trong pha validation. Nếu hợp lệ, giao tác được commit; nếu không, giao tác bị hủy và có thể được thực hiện lại với timestamp mới.

| 4 pha | 5 pha | 3 pha | Ý nghĩa |
| --- | --- | --- | --- |
| Read | R (Read) | Read phase | Đọc dữ liệu từ database vào local workspace |
| Compute | E (Execute) | | Chạy các lệnh logic tính toán |
|  | W (Write) | | Ghi dữ liệu từ local workspace trở lại database |
| Validate | V (Validate) | Validation phase | Kiểm tra xung đột với các giao tác khác |
| Write | C (Commit) | Write phase | Nếu hợp lệ, ghi dữ liệu vào database và commit; nếu không, hủy giao tác |

**Ba điều kiện kiểm tra hợp lệ:** Với mọi giao tác Tk mà ts(Tk) < ts(Tij):

- ***Điều kiện 1: Không chồng chéo***
    - Nếu tất cả các giao tác Tk đã hoàn thành pha TRƯỚC KHI Tij bắt đầu đọc &rarr; Validate thành công &rArr; Các transaction thực thi hoàn toàn nối tiếp.
- ***Điều kiện 2: Chồng chéo pha đọc - ghi, không có dữ liệu chung.***
    - Nếu Tk hoàn thành pha đọc trước khi Tij hoàn thành pha đọc, validate thành công nếu: 
        - WS(Tk) ∩ RS(Tij) = ∅ (không có dữ liệu chung được ghi bởi Tk và đọc bởi Tij).
    
    &rArr; Tij không đọc dữ liệu do Tk ghi, nên không có xung đột.
- ***Điều kiện 3: Chồng chéo pha hoàn toàn, không có dữ liệu chung.***
    - Nếu Tk hoàn thành pha đọc trước khi Tij hoàn thành pha đọc, validation thành công nếu:
        - WS(Tk) ∩ RS(Tij) = ∅ (không có dữ liệu chung được ghi bởi Tk và đọc bởi Tij).
        - WS(Tk) ∩ WS(Tij) = ∅ (không có dữ liệu chung được ghi bởi cả Tk và Tij).
    &rArr; Tij không đọc hoặc ghi dữ liệu do Tk ghi, nên không có xung đột.

---
## 8. Snapshot Isolation (SI)
Snapshot Isolation là cơ chế trong đó mỗi giao tác 'nhìn thấy' một ảnh chụp nhất quán (consistent snapshot) của CSDL tại thời điểm nó bắt đầu, và đọc/ghi trên ảnh chụp đó dựa trên kĩ thuật Row-versioning.

So sánh:
| Lock-base | Row-versioning |
| --- | --- |
| Dùng lock để đồng bộ hóa truy cập dữ liệu | Tạo ra nhiều phiên bản của dữ liệu để cho phép truy cập đồng thời |
| Thao tác đọc có thể chặn thao tác ghi và ngược lại | Thao tác đọc không chặn thao tác ghi và ngược lại |

Ví dụ: SQL server sử dụng kĩ thuật Row-versioning để đánh dấu phiên bản của mỗi bản ghi và lưu trong `tempdb` để hỗ trợ Snapshot Isolation. Khi có thao tác đọc và ghi đồng thời, thao tác đọc sẽ đọc các phiên bản cũ của dữ liệu trong `tempdb` thay vì chờ đợi thao tác ghi hoàn thành, giúp giảm thiểu xung đột và tăng hiệu suất. Tuy nhiên nếu có 2 thao tác ghi đồng thời, conflict sẽ xảy ra và một trong hai thao tác ghi sẽ bị hủy để đảm bảo tính nhất quán của dữ liệu.

**Đặc điểm:**
- Đọc lặp lại (Repeatable Reads): Các lần đọc trong cùng một giao tác luôn cho cùng kết quả.
- KHÔNG HOÀN TOÀN tuần tự hóa (Not Fully Serializable): Có thể xảy ra hiện tượng "write skew" khi hai giao tác cùng đọc một dữ liệu và sau đó ghi vào các dữ liệu khác dựa trên giá trị đã đọc, dẫn đến kết quả không nhất quán.
- Thao tác chỉ đọc không cần đồng bộ hóa nặng nề.

**Cơ chế SI tập trung (4 bước):**
- Bước 1: Ti bắt đầu, lấy begin timestamp tsb(Ti).
- Bước 2: Ti sẵn sàng commit, lấy commit timestamp tsc(Tj) lớn hơn mọi tsb hoặc tsc đã tồn tại.
- Bước 3: Ti commit NẾU không có Tj nào khác sao cho tsc(Tj) thuộc [tsb(Ti), tsc(Ti)] và WS(Tj) ∩ RS(Ti) ≠ ∅ (tức là không có giao tác nào khác ghi dữ liệu mà Ti đã đọc trong khoảng thời gian từ khi Ti bắt đầu đến khi Ti commit).
- Bước 4: Khi Ti commit, thay đổi hiển thị Tk nếu tsb(Tk) > tsc(Ti).

### Distribute CC with SI
Trong môi trường phân tán, việc tính toán 1 snapshot nhất quán trở nên phức tạp hơn do sự phân tán của dữ liệu và giao tác. Nó cần đảm bảo:
- Mỗi lịch sử cục bộ phải thỏa mãn SI cục bộ.
- Lịch sử toàn cục là SI --> thứ tự commit tại mọi site phải nhất quán với thứ tự commit toàn cục.

### Quan hệ phụ thuộc:
Tis phụ thuộc vào Tjs (dependenct(Tis, Tjs)) khi và chỉ khi:
- (RS(Tis) ∩ WS(Tjs)) ≠ ∅ (Tis đọc dữ liệu mà Tjs ghi) hoặc (WS(Tis) ∩ WS(Tjs)) ≠ ∅ (Tis và Tjs ghi cùng dữ liệu) hoặc (WS(Tis) ∩ RS(Tjs)) ≠ ∅ (Tis ghi dữ liệu mà Tjs đọc).

### Quy trình thực thi:
- TM điều phối hỏi các site về giao tác đồng thời và đồng hồ sự kiện.
- Mỗi site trả về tập giao tác đồng thời cục bộ.
- TM điều phối tổng hợp tập giao tác đồng thời toàn cục, gửi xuống các site.
- Mỗi site kiểm tra 2 điều kiện đầu tiên, trả về kết quả validation.
- Nếu có bất kỳ site nào validation âm → global abort (hủy bỏ trên tất cả các site).
- Nếu tất cả dương → global commit, các site cập nhật đồng hồ sự kiện.

