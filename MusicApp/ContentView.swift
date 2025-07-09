//
//  ContentView.swift
//  MusicApp
//
//  Created by Philippe Beland on 2025-07-08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "music.note")
                }
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    ContentView()
}
