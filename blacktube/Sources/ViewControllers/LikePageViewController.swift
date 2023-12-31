//
//  LikePageViewController.swift
//  blacktube
//
//  Created by Jongbum Lee on 2023/09/04.
//

import UIKit
import AVFoundation

class LikePageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    
    var videos: [Video] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        videos = loginUser.likedVideos
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAppLogoToNavigationBar()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail", let destinationVC = segue.destination as? DetailViewController, let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.video = videos[indexPath.row]
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as? CustomVideoCell else {
            return UITableViewCell()
        }
        
        let video = videos[indexPath.row]
        cell.titleLabel.text = video.title
        cell.channelLabel.text = video.channelTitle
        cell.viewCountLabel.text = "| 조회수 \(video.viewCount)"
        
        URLSession.shared.dataTask(with: video.thumbnailURL) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    cell.thumbnailImageView.image = image
                }
            }
        }.resume()
        
        return cell
    }
    
    func setAppLogoToNavigationBar() {
        let logoImageView = UIImageView(image: UIImage(named: "blacktube_applogo_black"))
        logoImageView.frame = CGRect(x: 20, y: 5, width: 40, height: 27)
        navigationBar.addSubview(logoImageView)
    }
}

class CustomVideoCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    
}

extension LikePageViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
