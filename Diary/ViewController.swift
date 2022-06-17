//
//  ViewController.swift
//  Diary
//
//  Created by 정유진 on 2022/04/01.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var diaryList = [Diary]() {
        didSet {
            self.saveDiaryList()
        }
    }
    //DiaryList 배열에 일기가 추가, 변경시 userDefaults에 저장됨
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollectionView()
        self.loadDiaryList()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(editDiaryNotification(_:)),
            name: NSNotification.Name("editDiary"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(starDiaryNotification(_:)),
            name: NSNotification.Name("starDiary"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deleteDiaryNotification(_:)),
            name: NSNotification.Name("deleteDiary"),
            object: nil
        )
        
    }
    
    private func configureCollectionView() {
        self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    @objc func editDiaryNotification(_ notification: Notification) {
        guard let diary = notification.object as? Diary else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == diary.uuidString }) else { return }
        self.diaryList[index] = diary
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        self.collectionView.reloadData()
    }
    
    @objc func starDiaryNotification(_ notification: Notification) {
        guard let starDiary = notification.object as? [String: Any] else { return }
        guard let isStar = starDiary["isStar"] as? Bool else { return }
        guard let uuidString = starDiary["uuidString"] as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
        self.diaryList[index].isStar = isStar
    }
    
    @objc func deleteDiaryNotification(_ notification: Notification) {
        guard let uuidString = notification.object as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
        self.diaryList.remove(at: index)
        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let writeDiaryViewController = segue.destination as? WriteDiaryViewController {
            writeDiaryViewController.delegate = self
        }
    }
    
    private func saveDiaryList() {
        //일기를 userDefaults에 Dictionary형태로 저장
        //map으로 배열에 있는 요소를 Dictionary형태로 mapping
        let date = self.diaryList.map {
            [
                "uuidString": $0.uuidString,
                "title": $0.title,
                "contents": $0.contents,
                "date": $0.date,
                "isStar": $0.isStar
            ]
        }
        //UserDefaults.standard로 userDefaults에 접근할 수 있게함
        let userDefaults = UserDefaults.standard
        userDefaults.set(date, forKey: "diaryList")
    }
    
    private func loadDiaryList() {
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.object(forKey: "diaryList") as? [[String: Any]] else { return }
        //"diaryList"키값으로 일기를불러옴
        self.diaryList = data.compactMap {
            guard let uuidString = $0["uuidString"] as? String else { return nil }
            guard let title = $0["title"] as? String else { return nil }
            guard let contents = $0["contents"] as? String else { return nil }
            guard let date = $0["date"] as? Date else { return nil }
            guard let isStar = $0["isStar"] as? Bool else { return nil}
            return Diary(uuidString: uuidString, title: title, contents: contents, date: date, isStar: isStar)
            //return diary 타입이 되게 인스턴스화 해준다
        }
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
    }
    
    //데이트타입을 전달받으면 문자열로 변환
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    
}
extension ViewController: UICollectionViewDataSource {
    //콜렉션뷰에서 데이터 소스는 콜렉션뷰로 보여주는 콘텐츠를 관리하는 객체
    //필수메서드
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //지정된 섹션에 표시 할 셀의 갯수를 묻는 메서드.
        //diaryList배열의 갯수만큼 셀이 표시되게 구현
        return self.diaryList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //콜렉션뷰에 지정된 위치에 표시할 셀을 요청하는 메서드
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiaryCell", for: indexPath) as? DiaryCell else { return UICollectionViewCell() }
        //storyBoard에서 구성한 CustomCell을 가져온다
        //as? DiaryCell 다이어리셀로 다운캐스팅, 실패시 빈UICollectionViewCell이 반환
        
        //withReuseIdentifier 파라미터로 전달받은 "DiaryCell" 재사용식별자를 통해 재사용가능한 콜렉션뷰 셀을 찾고 이를 반환
        //이렇게 재사용할 셀을 가져오면 이 셀에 일기의 제목과 날짜가 표시되게 구현
        let diary = self.diaryList[indexPath.row]
        //저장되어있는 배열에 indexPath.row값으로 일기를 가져온다
        cell.titleLabel.text = diary.title
        cell.dateLabel.text = self.dateToString(date: diary.date)
        //다이어리 인스턴스에 있는 date프로퍼티는 date타입으로 되어있어 dateCollector로 문자열로 변환 (함수구현)
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    //sizeForItemAt 메서드는 셀의 사이즈를 설정하는 역할 CG값으로설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //셀이 행에 두개씩 표시되게 구현 (contentInset에서 설정한 좌우값도 빼줌)
        return CGSize(width: (UIScreen.main.bounds.width / 2) - 20, height: 200)
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //특정 cell 선택 알림 , DiaryDetailViewController가 push
        guard let viewController = self.storyboard?.instantiateViewController(identifier: "DiaryDetailViewController") as? DiaryDetailViewController else { return }
        let diary = self.diaryList[indexPath.row]
        viewController.diary = diary
        viewController.indexPath = indexPath
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension ViewController: WriteDiaryViewDelegate {
    /*일기가 작성이 되면 didSelectReigster 메서드 파라미터를 통해
     작성된 일기에 내용이 담겨져 있는 Diary객체를 전달 */
    func didSelectReigster(diary: Diary) {
        //Diary 객체를 diaryList.append로 추가해준다
        self.diaryList.append(diary)
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        self.collectionView.reloadData()
    }
}

