//
//  ViewController.swift
//  blacktube
//
//  Created by Sanghun K. on 2023/09/04.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var navigationBar: UINavigationBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videos = []
        tableView.dataSource = self
        tableView.delegate = self
        CheckDarkMode()
        setAppLogoToNavigationBar()
        fetchYoutubeData()
    }
    
    func fetchYoutubeData() {
        guard let url = URL(string: "https://youtube.googleapis.com/youtube/v3/videos?part=snippet%2Cstatistics&chart=mostPopular&maxResults=25&key=AIzaSyD0zgyg0KvAu75CFl-kHfLNt8Mz_mCblx0") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                return
            }
            
            // API에서 받아온 데이터를 파싱하여 Video 객체로 변환하고 배열에 저장
            for item in items {
                if let snippet = item["snippet"] as? [String: Any],
                   let statistics = item["statistics"] as? [String: Any],
                   let viewCount = statistics["viewCount"] as? String,
                   let channelTitle = snippet["channelTitle"] as? String,
                   let thumbnails = snippet["thumbnails"] as? [String: Any],
                   let standardThumbnail = thumbnails["standard"] as? [String: Any],
                   let thumbnailURL = URL(string: standardThumbnail["url"] as! String),
                   let tags = snippet["tags"] as? [String],
                   let publishedDate = snippet["publishedAt"] as? String,
                   let videoId = item["id"] as? String,
                   let description = snippet["description"] as? String,
                   let title = snippet["title"] as? String {
                    
                    let video = Video(
                        title: title,
                        thumbnailURL: thumbnailURL,
                        viewCount: viewCount,
                        channelTitle: channelTitle,
                        tags: tags,
                        publishedDate: publishedDate,
                        videoId: videoId,
                        description: description,
                        isLiked: false
                    )
                    videos.append(video)
                }
            }
            
            // UI 업데이트는 메인 스레드에서 수행해야 함
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }.resume()
    }
    
    func setAppLogoToNavigationBar() {
        let logoImageView = UIImageView(image: UIImage(named: "blacktube_applogo_black"))
        logoImageView.frame = CGRect(x: 20, y: 5, width: 40, height: 27)
        navigationBar.addSubview(logoImageView)
    }
    
    @objc func Tapped (_ sender: UIButton) {
        if sender.imageView?.image == UIImage(systemName: "heart.fill")?.imageWithColor(color: UIColor.red) {
            sender.setImage(UIImage(systemName: "heart")?.imageWithColor(color: UIColor.gray), for: .normal)
        }
        else {
            sender.setImage(UIImage(systemName: "heart.fill")?.imageWithColor(color: UIColor.red), for: .normal)
        }
    }
    
    func CheckDarkMode() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        if loginUser.isDarkMode{
            window.overrideUserInterfaceStyle = .dark
        }
        else {
            window.overrideUserInterfaceStyle = .light
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as! MainTableViewCell
        
        let video = videos[indexPath.row]
        
        cell.titleLabel.text = video.title
        
        if let viewCountInt = Int(video.viewCount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if let formattedViewCount = formatter.string(from: NSNumber(value:viewCountInt)) {
                cell.viewCountLabel.text = "\(formattedViewCount) views"
                cell.viewCountLabel.font = UIFont.systemFont(ofSize: 12,weight: .thin)
            }
        }
        
        cell.channelLabel.text = "\(video.channelTitle)  ·"
        cell.channelLabel.font = UIFont.systemFont(ofSize: 12, weight: .thin)
        
        cell.heartButton.isSelected = false
        cell.heartButton.tintColor = .clear
        cell.heartButton.addTarget(self, action: #selector(Tapped), for: .touchUpInside)
        
        if loginUser.likedVideos.contains(video) {
            let filledHeart = UIImage(systemName: "heart.fill")?.imageWithColor(color: UIColor.red)
            cell.heartButton.setImage(filledHeart, for: .normal)
        }
        else {
            let heart = UIImage(systemName: "heart")?.imageWithColor(color: UIColor.gray)
            cell.heartButton.setImage(heart, for: .normal)
        }
        
        cell.heartButton.tag = indexPath.row
        
        DispatchQueue.global().async {
            if let imageData = try? Data(contentsOf: video.thumbnailURL) {
                let image = UIImage(data: imageData)
                DispatchQueue.main.async {
                    cell.thumbnailView.image = image
                }
            }
        }
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedVideo = videos[indexPath.row]
        performSegue(withIdentifier: "MainToDetail", sender: selectedVideo)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MainToDetail" {
            if let detailVC = segue.destination as? DetailViewController {
                if let selectedVideo = sender as? Video {
                    detailVC.video = selectedVideo
                }
            }
        }
    }
}

extension ViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
