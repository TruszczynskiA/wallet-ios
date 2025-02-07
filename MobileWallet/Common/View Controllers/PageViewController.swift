//  PageViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/01/2022
	Using Swift 5.0
	Running on macOS 12.1

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

final class PageViewController: UIViewController {

    // MARK: - Properties

    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    var controllers: [UIViewController] = [] {
        didSet { move(toIndex: 0) }
    }

    private var scrollView: UIScrollView? {
        pageViewController.view.subviews
           .compactMap { $0 as? UIScrollView }
           .first
    }

    private var currentIndex = 0

    @Published private(set) var pageIndex: CGFloat = 0.0

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupViews() {
        add(childController: pageViewController, containerView: view)
    }

    private func setupCallbacks() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        scrollView?.delegate = self
    }

    // MARK: - Actions

    func move(toIndex index: Int) {
        guard let controller = controller(forIndex: index) else { return }
        scrollView?.panGestureRecognizer.isEnabled = false
        scrollView?.panGestureRecognizer.isEnabled = true
        pageViewController.setViewControllers([controller], direction: index > currentIndex ? .forward : .reverse, animated: true) { [weak self] _ in
            self?.currentIndex = index
        }
    }

    // MARK: - Helpers

    private func controller(forIndex index: Int) -> UIViewController? {
        guard index >= 0, index < controllers.count else { return nil }
        return controllers[index]
    }
}

extension PageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController) else { return nil }
        return controller(forIndex: index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController) else { return nil }
        return controller(forIndex: index + 1)
    }
}

extension PageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let controller = pageViewController.viewControllers?.first, let index = controllers.firstIndex(of: controller) else { return }
        currentIndex = index
    }
}

extension PageViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let offset = scrollView.contentOffset.x
        let bounds = scrollView.bounds.width
        let index = CGFloat(currentIndex)

        pageIndex = offset / bounds + index - 1
    }
}
