//
//  IssueCell.swift
//  SwiftHub
//
//  Created by Sygnoos9 on 11/20/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift

class IssueCell: DefaultTableViewCell {

    /// 官方列表用状态图标代替头像
    private lazy var stateImageView: ImageView = {
        let view = ImageView()
        view.contentMode = .scaleAspectFit
        view.snp.makeConstraints({ (make) in
            make.size.equalTo(16)
        })
        return view
    }()

    override func makeUI() {
        super.makeUI()
        titleLabel.numberOfLines = 2
        leftImageView.isHidden = true
        stackView.insertArrangedSubview(stateImageView, at: 0)
    }

    override func bind(to viewModel: TableViewCellViewModel) {
        super.bind(to: viewModel)
        guard let viewModel = viewModel as? IssueCellViewModel else { return }
        cellDisposeBag = DisposeBag()

        leftImageView.rx.tap().map { _ in viewModel.issue.user }.filterNil()
            .bind(to: viewModel.userSelected).disposed(by: cellDisposeBag)

        // open = 绿色圆点，closed = 紫色对勾（与官方一致）
        let isClosed = viewModel.issue.state == .closed
        stateImageView.image = UIImage(systemName: isClosed ? "checkmark.circle" : "smallcircle.filled.circle")
        stateImageView.tintColor = isClosed ? UIColor.GitHub.merged : UIColor.GitHub.open
    }
}
