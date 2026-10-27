//
//  EventsViewModel.swift
//  SwiftHub
//
//  Created by Sygnoos9 on 9/6/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources

enum EventsMode {
    case repository(repository: Repository)
    case user(user: User)
    /// 首页关注流：没有官方 feed 接口，用"关注对象的公开事件"聚合近似
    case following
}

class EventsViewModel: ViewModel, ViewModelType {

    struct Input {
        let headerRefresh: Observable<Void>
        let footerRefresh: Observable<Void>
        let segmentSelection: Observable<EventSegments>
        let selection: Driver<EventCellViewModel>
    }

    struct Output {
        let navigationTitle: Driver<String>
        let imageUrl: Driver<URL?>
        let items: BehaviorRelay<[EventCellViewModel]>
        let userSelected: Driver<UserViewModel>
        let repositorySelected: Driver<RepositoryViewModel>
        let hidesSegment: Driver<Bool>
    }

    let mode: BehaviorRelay<EventsMode>
    let segment = BehaviorRelay<EventSegments>(value: .received)
    let userSelected = PublishSubject<User>()

    init(mode: EventsMode, provider: SwiftHubAPI) {
        self.mode = BehaviorRelay(value: mode)
        super.init(provider: provider)
        switch mode {
        case .repository(let repository):
            if let fullname = repository.fullname {
                analytics.log(.repositoryEvents(fullname: fullname))
            }
        case .user(let user):
            if let login = user.login {
                analytics.log(.userEvents(login: login))
            }
        case .following:
            if let login = User.currentUser()?.login {
                analytics.log(.userEvents(login: login))
            }
        }
    }

    func transform(input: Input) -> Output {
        let elements = BehaviorRelay<[EventCellViewModel]>(value: [])

        input.segmentSelection.bind(to: segment).disposed(by: rx.disposeBag)

        input.headerRefresh.flatMapLatest({ [weak self] () -> Observable<[EventCellViewModel]> in
            guard let self = self else { return Observable.just([]) }
            self.page = 1
            return self.request()
                .trackActivity(self.headerLoading)
        })
            .subscribe(onNext: { (items) in
                elements.accept(items)
            }).disposed(by: rx.disposeBag)

        input.footerRefresh.flatMapLatest({ [weak self] () -> Observable<[EventCellViewModel]> in
            guard let self = self else { return Observable.just([]) }
            self.page += 1
            return self.request()
                .trackActivity(self.footerLoading)
        })
            .subscribe(onNext: { (items) in
                elements.accept(elements.value + items)
            }).disposed(by: rx.disposeBag)

        let userDetails = userSelected.asDriver(onErrorJustReturn: User())
            .map({ (user) -> UserViewModel in
                let viewModel = UserViewModel(user: user, provider: self.provider)
                return viewModel
            })

        let repositoryDetails = input.selection.map { $0.event.repository }.filterNil()
            .map({ (repository) -> RepositoryViewModel in
                let viewModel = RepositoryViewModel(repository: repository, provider: self.provider)
                return viewModel
            })

        let navigationTitle = mode.map({ (mode) -> String in
            switch mode {
            case .following: return L(.homeTabBarHomeTitle)
            default: return L(.eventsNavigationTitle)
            }
        }).asDriver(onErrorJustReturn: "")

        let imageUrl = mode.map({ (mode) -> URL? in
            switch mode {
            case .repository(let repository): return repository.owner?.avatarUrl?.url
            case .user(let user): return user.avatarUrl?.url
            case .following: return User.currentUser()?.avatarUrl?.url
            }
        }).asDriver(onErrorJustReturn: nil)

        let hidesSegment = mode.map { (mode) -> Bool in
            switch mode {
            case .repository: return true
            case .following: return true
            case .user(let user):
                switch user.type {
                case .user: return false
                case .organization: return true
                }
            }
        }.asDriver(onErrorJustReturn: false)

        return Output(navigationTitle: navigationTitle,
                      imageUrl: imageUrl,
                      items: elements,
                      userSelected: userDetails,
                      repositorySelected: repositoryDetails,
                      hidesSegment: hidesSegment)
    }

    func request() -> Observable<[EventCellViewModel]> {
        var request: Single<[Event]>
        switch mode.value {
        case .repository(let repository):
            request = provider.repositoryEvents(owner: repository.owner?.login ?? "", repo: repository.name ?? "", page: page)
        case .following:
            request = followingFeed()
        case .user(let user):
            switch user.type {
            case .user:
                switch segment.value {
                case .performed: request = provider.userPerformedEvents(username: user.login ?? "", page: page)
                case .received: request = provider.userReceivedEvents(username: user.login ?? "", page: page)
                }
            case .organization: request = provider.organizationEvents(username: user.login ?? "", page: page)
            }
        }
        return request
            .trackActivity(loading)
            .trackError(error)
            .map { $0.map({ (event) -> EventCellViewModel in
                let viewModel = EventCellViewModel(with: event)
                viewModel.userSelected.bind(to: self.userSelected).disposed(by: self.rx.disposeBag)
                return viewModel
            })}
    }

    // MARK: - 关注流

    /// 一次聚合多少个关注对象的事件。太大首屏会慢，也会吃限流额度
    private static let feedFollowingLimit = 12

    /// GitHub 没有开放 "following feed" 接口（官方走私有时间线），
    /// 这里取关注对象最近的公开事件按时间合并，是公开 API 下最接近的近似。
    private func followingFeed() -> Single<[Event]> {
        guard let login = User.currentUser()?.login else { return .just([]) }
        return provider.userFollowing(username: login, page: 1)
            .flatMap { [weak self] users -> Single<[Event]> in
                guard let self = self else { return .just([]) }
                let singles = users.prefix(EventsViewModel.feedFollowingLimit).compactMap { user -> Single<[Event]>? in
                    guard let login = user.login else { return nil }
                    return self.provider.userReceivedEvents(username: login, page: 1)
                        .catchAndReturn([])
                }
                guard !singles.isEmpty else { return .just([]) }
                return Single.zip(singles).map { batches in
                    batches.flatMap { $0 }
                        .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                }
            }
    }

}
