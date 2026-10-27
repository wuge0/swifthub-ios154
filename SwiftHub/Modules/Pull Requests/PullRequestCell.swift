//
//  PullRequestCell.swift
//  SwiftHub
//
//  Created by Sygnoos9 on 11/30/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift

class PullRequestCell: DefaultTableViewCell {

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
        guard let viewModel = viewModel as? PullRequestCellViewModel else { return }
        cellDisposeBag = DisposeBag()

        leftImageView.rx.tap().map { _ in viewModel.pullRequest.user }.filterNil()
            .bind(to: viewModel.userSelected).disposed(by: cellDisposeBag)

        // merged = 紫色合并箭头，closed = 红色叉，open = 绿色 PR 箭头
        let pullRequest = viewModel.pullRequest
        let isMerged = pullRequest.merged == true
        let isClosed = pullRequest.state == .closed
        let symbol = isMerged ? "arrow.triangle.merge" : (isClosed ? "xmark.circle" : "arrow.triangle.pull")
        stateImageView.image = UIImage(systemName: symbol)
        stateImageView.tintColor = isMerged ? UIColor.GitHub.merged
            : (isClosed ? UIColor.GitHub.closed : UIColor.GitHub.open)
    }
}
