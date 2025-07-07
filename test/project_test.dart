import 'dart:io';
import 'package:test/test.dart';
import 'package:pkl_dart/pkl_dart.dart';
import 'package:pkl_dart/src/project.dart';

void main() {
  group('Project Evaluation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pkl_project_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // This test verifies that the Project class can be correctly deserialized
    // from an evaluated PklProject file.
    test('deserializes a Project object correctly', () async {
      final projectDir = _createProjectFixtures(tempDir, 'project');
      final pklProjectPath = '${projectDir.path}/PklProject';

      await withEvaluatorPreconfigured((evaluator) async {
        // Evaluate the PklProject file itself as a module
        final result =
            await evaluator.evaluateModule(ModuleSource.uri(Uri.file(pklProjectPath)))
                as Map<String, dynamic>;

        final project = Project.fromJson(result);

        final expectedPackage = Package(
          name: 'hawk',
          baseUri: 'package://example.com/hawk',
          version: '0.5.0',
          packageZipUrl: 'https://example.com/hawk/0.5.0/hawk-0.5.0.zip',
          description: 'Some project about hawks',
          authors: const ['Birdy Bird <birdy@bird.com>'],
          website: 'https://example.com/my/website',
          documentation: 'https://example.com/my/docs',
          sourceCode: 'https://example.com/my/repo',
          sourceCodeUrlScheme: 'https://example.com/my/repo/0.5.0%{path}',
          license: 'MIT',
          licenseText: '# Some License text\n\nThis is my license text',
          issueTracker: 'https://example.com/my/issues',
          apiTests: const ['apiTest1.pkl', 'apiTest2.pkl'],
          exclude: const ['PklProject', 'PklProject.deps.json', '.**', '*.exe'],
          uri: 'package://example.com/hawk@0.5.0',
        );
        expect(project.package, equals(expectedPackage));

        expect(project.tests, equals(['test1.pkl', 'test2.pkl']));
      });
    });
  });
}

// Helper function to create test fixture files
Directory _createProjectFixtures(Directory tempDir, String fixtureSetName) {
  final projectDir = Directory('${tempDir.path}/$fixtureSetName')..createSync(recursive: true);
  switch (fixtureSetName) {
    case 'project':
      File('${projectDir.path}/PklProject').writeAsStringSync(_pklProjectFileContent);
      Directory('${projectDir.path}/cache').createSync();
      Directory('${projectDir.path}/modulepath1').createSync();
      Directory('${projectDir.path}/modulepath2').createSync();
      File('${projectDir.path}/apiTest1.pkl').createSync();
      File('${projectDir.path}/apiTest2.pkl').createSync();
      File('${projectDir.path}/test1.pkl').createSync();
      File('${projectDir.path}/test2.pkl').createSync();
      break;
    case 'project_wrong_type':
      File('${projectDir.path}/PklProject').writeAsStringSync('module com.apple.Foo\n\nfoo = 1');
      break;
    case 'project_cycle':
      final p1Dir = Directory('${projectDir.path}/project1')..createSync();
      final p2Dir = Directory('${projectDir.path}/project2')..createSync();
      File('${p1Dir.path}/PklProject').writeAsStringSync(
        'amends "pkl:Project"\ndependencies { ["p2"] = import("../project2/PklProject") }',
      );
      File('${p2Dir.path}/PklProject').writeAsStringSync(
        'amends "pkl:Project"\ndependencies { ["p1"] = import("../project1/PklProject") }',
      );
      break;
  }
  return projectDir;
}

const _pklProjectFileContent = r'''
      @Deprecated { since = "1.2"; message = "do not use"; replaceWith = "somethingElse" }
      @Unlisted
      @ModuleInfo { minPklVersion = "0.26.0" }
      amends "pkl:Project"

      evaluatorSettings {
        timeout = 5.min
        rootDir = "."
        noCache = false
        moduleCacheDir = "cache/"
        env {
          ["one"] = "1"
        }
        externalProperties {
          ["two"] = "2"
        }
        modulePath {
          "modulepath1/"
          "modulepath2/"
        }
        allowedModules {
          "foo:"
          "bar:"
        }
        allowedResources {
          "baz:"
          "biz:"
        }
      }

      package {
        name = "hawk"
        baseUri = "package://example.com/hawk"
        version = "0.5.0"
        description = "Some project about hawks"
        packageZipUrl = "https://example.com/hawk/\(version)/hawk-\(version).zip"
        authors {
          "Birdy Bird <birdy@bird.com>"
        }
        license = "MIT"
        sourceCode = "https://example.com/my/repo"
        sourceCodeUrlScheme = "https://example.com/my/repo/\(version)%{path}"
        documentation = "https://example.com/my/docs"
        website = "https://example.com/my/website"
        licenseText = """
          # Some License text
          
          This is my license text
          """
        apiTests {
          "apiTest1.pkl"
          "apiTest2.pkl"
        }
        exclude { "*.exe" }
        issueTracker = "https://example.com/my/issues"
      }
      
      tests {
        "test1.pkl"
        "test2.pkl"
      }
''';
