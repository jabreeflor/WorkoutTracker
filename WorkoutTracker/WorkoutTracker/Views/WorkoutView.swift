import SwiftUI
import CoreData

struct WorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.lastModifiedDate, ascending: false)],
        animation: .default
    ) private var templates: FetchedResults<WorkoutTemplate>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Folder.name, ascending: true)],
        animation: .default
    ) private var folders: FetchedResults<Folder>
    
    @State private var showingWorkoutSession = false
    @State private var showingNewFolder = false
    @State private var showingTemplateBuilder = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var currentFolder: Folder?
    @State private var newFolderName = ""
    
    private var currentTemplates: [WorkoutTemplate] {
        return templates.filter { template in
            template.folder == currentFolder
        }
    }
    
    private var currentSubFolders: [Folder] {
        return folders.filter { folder in
            folder.parentFolder == currentFolder
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick Start Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Start")
                            .font(.headline)
                            .bold()
                        
                        Button(action: {
                            showingWorkoutSession = true
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Start Empty Workout")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Navigation Breadcrumb
                    if currentFolder != nil {
                        HStack {
                            Button("All Templates") {
                                currentFolder = nil
                            }
                            .foregroundColor(.blue)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                            
                            Text(currentFolder?.name ?? "")
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Folders Section
                    if !currentSubFolders.isEmpty || currentFolder == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Folders")
                                    .font(.headline)
                                    .bold()
                                
                                Spacer()
                                
                                Button(action: {
                                    showingNewFolder = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(currentSubFolders, id: \.id) { folder in
                                    FolderTile(folder: folder) {
                                        currentFolder = folder
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Templates Section - Centered
                    VStack(spacing: 12) {
                        HStack {
                            Text("Templates")
                                .font(.headline)
                                .bold()
                            
                            Spacer()
                            
                            Button(action: {
                                showingTemplateBuilder = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                    Text("Create")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if currentTemplates.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No templates yet")
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 8) {
                                    Button(action: {
                                        showingTemplateBuilder = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Create Template")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                    }
                                    
                                    Text("Or complete a workout and save it as a template!")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(currentTemplates, id: \.id) { template in
                                    TemplateTile(template: template) {
                                        startWorkoutFromTemplate(template)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Workout")
            .sheet(isPresented: $showingWorkoutSession) {
                if let template = selectedTemplate {
                    WorkoutSessionView(template: template)
                } else {
                    WorkoutSessionView()
                }
            }
            .sheet(isPresented: $showingNewFolder) {
                NewFolderView(parentFolder: currentFolder)
            }
            .sheet(isPresented: $showingTemplateBuilder) {
                TemplateBuilderView()
            }
        }
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        selectedTemplate = template
        showingWorkoutSession = true
    }
}

#Preview {
    WorkoutView()
}