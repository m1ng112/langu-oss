import Foundation

enum ContentLoader {
    // MARK: - Loaded content

    static let units: [LessonUnit] = loadUnits()

    static let lessons: [Lesson] = units.flatMap(\.lessons)

    static let stories: [Story] = loadStories()

    static let themes: [Theme] = loadThemes()

    // MARK: - Loading

    private static func loadUnits() -> [LessonUnit] {
        let wrapper: UnitsWrapper = load("units")
        return wrapper.units
    }

    private static func loadStories() -> [Story] {
        let wrapper: StoriesWrapper = load("stories")
        return wrapper.stories
    }

    private static func loadThemes() -> [Theme] {
        let wrapper: ThemesWrapper = load("themes")
        return wrapper.themes
    }

    private static func load<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Missing \(name).json in bundle")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Cannot read \(name).json")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("Cannot decode \(name).json: \(error)")
        }
    }

    // MARK: - JSON wrappers

    private struct UnitsWrapper: Codable {
        let units: [LessonUnit]
    }

    private struct StoriesWrapper: Codable {
        let stories: [Story]
    }

    private struct ThemesWrapper: Codable {
        let themes: [Theme]
    }
}
