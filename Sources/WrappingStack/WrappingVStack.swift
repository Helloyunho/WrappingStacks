//
//  WrappingVStack.swift
//  LayoutPlayground
//
//  Created by Konstantin Semianov on 11/30/22.
//  Modified by Helloyunho on 6/23/24.
//

import SwiftUI

/// A view that arranges its subviews in vertical line and wraps them to the next columns if necessary.
public struct WrappingVStack: Layout {
    /// The guide for aligning the subviews in this stack. This guide has the same screen coordinate for every subview.
    public var alignment: Alignment

    /// The distance between adjacent subviews in a column or `nil` if you want the stack to choose a default distance.
    public var verticalSpacing: CGFloat?

    /// The distance between consequtive columns or`nil` if you want the stack to choose a default distance.
    public var horizontalSpacing: CGFloat?

    /// Determines if the height of the stack should adjust to fit its content.
    ///
    /// If set to `true`, the stack's height will be based on its content rather than filling the available height.
    /// If set to `false` (default), it will occupy the full available height.
    public var fitContentHeight: Bool

    /// Creates a wrapping vertical stack with the given spacings and alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This guide has the same screen coordinate for every subview.
    ///   - verticalSpacing: The distance between adjacent subviews in a column or `nil` if you want the stack to choose a default distance.
    ///   - horizontalSpacing: The distance between consequtive columns or`nil` if you want the stack to choose a default distance.
    ///   - fitContentHeight: Determines if the height of the stack should adjust to fit its content.
    ///   - content: A view builder that creates the content of this stack.
    @inlinable public init(
        alignment: Alignment = .center,
        verticalSpacing: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        fitContentHeight: Bool = false
    ) {
        self.alignment = alignment
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
        self.fitContentHeight = fitContentHeight
    }

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical

        return properties
    }

    /// A shared computation between `sizeThatFits` and `placeSubviews`.
    public struct Cache {

        /// The minimal size of the view.
        var minSize: CGSize

        /// The cached columns.
        var columns: (Int, [Column])?
    }

    public func makeCache(subviews: Subviews) -> Cache {
        Cache(minSize: minSize(subviews: subviews))
    }

    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.minSize = minSize(subviews: subviews)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let columns = arrangeColumns(proposal: proposal, subviews: subviews, cache: &cache)

        if columns.isEmpty { return cache.minSize }

        var width: CGFloat = .zero
        if let lastColumn = columns.last {
            width = lastColumn.xOffset + lastColumn.width
        }

        var height: CGFloat = columns.map { $0.height }.reduce(.zero) { max($0, $1) }

        if !fitContentHeight, let proposalHeight = proposal.height {
            height = max(height, proposalHeight)
        }

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let columns = arrangeColumns(proposal: proposal, subviews: subviews, cache: &cache)

        let anchor = UnitPoint(alignment)

        for column in columns {
            for element in column.elements {
                let x: CGFloat = column.xOffset + anchor.x * (column.width - element.size.width)
                let y: CGFloat = element.yOffset + anchor.y * (bounds.height - column.height)
                let point = CGPoint(x: x + bounds.minX, y: y + bounds.minY)

                subviews[element.index].place(at: point, anchor: .topLeading, proposal: proposal)
            }
        }
    }
}

extension WrappingVStack {
    struct Column {
        var elements: [(index: Int, size: CGSize, yOffset: CGFloat)] = []
        var xOffset: CGFloat = .zero
        var width: CGFloat = .zero
        var height: CGFloat = .zero
    }

    private func arrangeColumns(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> [Column] {
        if subviews.isEmpty {
            return []
        }

        if cache.minSize.height > proposal.height ?? .infinity,
            cache.minSize.width > proposal.width ?? .infinity
        {
            return []
        }

        let sizes = subviews.map { $0.sizeThatFits(proposal) }

        let hash = computeHash(proposal: proposal, sizes: sizes)
        if let (oldHash, oldColumns) = cache.columns,
            oldHash == hash
        {
            return oldColumns
        }

        var currentY = CGFloat.zero
        var currentColumn = Column()
        var columns = [Column]()

        for index in subviews.indices {
            var spacing = CGFloat.zero
            if let previousIndex = currentColumn.elements.last?.index {
                spacing = verticalSpacing(subviews[previousIndex], subviews[index])
            }

            let size = sizes[index]

            if currentY + size.height + spacing > proposal.height ?? .infinity,
                !currentColumn.elements.isEmpty
            {
                currentColumn.height = currentY
                columns.append(currentColumn)
                currentColumn = Column()
                spacing = .zero
                currentY = .zero
            }

            currentColumn.elements.append((index, sizes[index], currentY + spacing))
            currentY += size.height + spacing
        }

        if !currentColumn.elements.isEmpty {
            currentColumn.height = currentY
            columns.append(currentColumn)
        }

        var currentX = CGFloat.zero
        var previousMaxWidthIndex: Int?

        for index in columns.indices {
            let maxWidthIndex = columns[index].elements
                .max { $0.size.width < $1.size.width }!
                .index

            let size = sizes[maxWidthIndex]

            var spacing = CGFloat.zero
            if let previousMaxWidthIndex {
                spacing = horizontalSpacing(
                    subviews[previousMaxWidthIndex], subviews[maxWidthIndex])
            }

            columns[index].xOffset = currentX + spacing
            currentX += size.width + spacing
            columns[index].width = size.width
            previousMaxWidthIndex = maxWidthIndex
        }

        cache.columns = (hash, columns)

        return columns
    }

    private func computeHash(proposal: ProposedViewSize, sizes: [CGSize]) -> Int {
        let proposal = proposal.replacingUnspecifiedDimensions(by: .infinity)

        var hasher = Hasher()

        for size in [proposal] + sizes {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }

        return hasher.finalize()
    }

    private func minSize(subviews: Subviews) -> CGSize {
        subviews
            .map { $0.sizeThatFits(.zero) }
            .reduce(CGSize.zero) {
                CGSize(width: max($0.width, $1.width), height: max($0.height, $1.height))
            }
    }

    private func horizontalSpacing(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        if let horizontalSpacing { return horizontalSpacing }

        return lhs.spacing.distance(to: rhs.spacing, along: .horizontal)
    }

    private func verticalSpacing(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        if let verticalSpacing { return verticalSpacing }

        return lhs.spacing.distance(to: rhs.spacing, along: .vertical)
    }
}

extension CGSize {
    fileprivate static var infinity: Self {
        .init(width: CGFloat.infinity, height: CGFloat.infinity)
    }
}

extension UnitPoint {
    fileprivate init(_ alignment: Alignment) {
        switch alignment {
        case .leading:
            self = .leading
        case .topLeading:
            self = .topLeading
        case .top:
            self = .top
        case .topTrailing:
            self = .topTrailing
        case .trailing:
            self = .trailing
        case .bottomTrailing:
            self = .bottomTrailing
        case .bottom:
            self = .bottom
        case .bottomLeading:
            self = .bottomLeading
        default:
            self = .center
        }
    }
}
